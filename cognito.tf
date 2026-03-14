###############################################################################
# Terraform – AWS Cognito User Pool + Post Confirmation Lambda Trigger
#
# Flow:
#   User confirms signup / Google federated login → Cognito fires post
#   confirmation trigger → Lambda writes item to DynamoDB:
#     PK = "user#<sub>"
#     SK = "Metadata"
#     + email, name, username, phone, picture, provider,
#       created_at, updated_at, email_verified, status
#
# Prerequisites (outside Terraform):
#   1. Create a Google OAuth2 client in Google Cloud Console:
#      https://console.cloud.google.com/apis/credentials
#   2. Add this as an Authorized redirect URI in Google Cloud Console:
#      https://<var.cognito_domain>.auth.<region>.amazoncognito.com/oauth2/idpresponse
#   3. Supply the client ID and secret via var.google_client_id / var.google_client_secret
###############################################################################


###############################################################################
# IAM Role for Post Confirmation Lambda
###############################################################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "post_confirmation_lambda" {
  name               = "post-confirmation-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags
}

# Basic execution — allows writing CloudWatch logs.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.post_confirmation_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow Lambda to write items into the DynamoDB table.
data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      aws_dynamodb_table.main.arn,
      "${aws_dynamodb_table.main.arn}/index/*", # Allow writes to GSI if needed
    ]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "post-confirmation-dynamodb-policy"
  role   = aws_iam_role.post_confirmation_lambda.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

###############################################################################
# Post Confirmation Lambda
###############################################################################

# Package the Lambda from local handler
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambdas/user_registration/index.py"
  output_path = "${path.module}/lambdas/user_registration/lambda.zip"
}

resource "aws_lambda_function" "post_confirmation" {
  function_name    = "cognito-post-confirmation"
  role             = aws_iam_role.post_confirmation_lambda.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  # Free tier: 128 MB memory, up to 1M invocations/month free.
  memory_size = 128
  timeout     = 10

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.main.name
    }
  }

  tags = merge(var.tags, { Name = "cognito-post-confirmation" })
}

# Allow Cognito to invoke this Lambda.
resource "aws_lambda_permission" "cognito_invoke" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.main.arn
}

###############################################################################
# Cognito User Pool
###############################################################################

resource "aws_cognito_user_pool" "main" {
  name = var.user_pool_name

  # Users sign in with their email address.
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # Password policy — reasonable defaults, free tier friendly.
  password_policy {
    minimum_length                   = 8
    require_uppercase                = true
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = false
    temporary_password_validity_days = 7
  }

  # Standard attributes collected at sign-up.
  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true

    string_attribute_constraints {
      min_length = 5
      max_length = 254
    }
  }

  schema {
    name                = "given_name"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  schema {
    name                = "family_name"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 1
      max_length = 100
    }
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 20
    }
  }

  # picture is needed to store the Google profile photo URL.
  schema {
    name                = "picture"
    attribute_data_type = "String"
    required            = false
    mutable             = true

    string_attribute_constraints {
      min_length = 0
      max_length = 2048
    }
  }

  # Account recovery via email.
  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  # Post confirmation trigger — fires after user verifies their email.
  lambda_config {
    post_confirmation = aws_lambda_function.post_confirmation.arn
  }

  tags = merge(var.tags, { Name = var.user_pool_name })
}

###############################################################################
# Cognito Hosted UI Domain
###############################################################################

resource "aws_cognito_user_pool_domain" "main" {
  domain       = var.cognito_domain
  user_pool_id = aws_cognito_user_pool.main.id
}

###############################################################################
# Google Identity Provider
###############################################################################

resource "aws_cognito_identity_provider" "google" {
  user_pool_id  = aws_cognito_user_pool.main.id
  provider_name = "Google"
  provider_type = "Google"

  provider_details = {
    client_id                     = var.google_client_id
    client_secret                 = var.google_client_secret
    authorize_scopes              = "openid email profile"
    oidc_issuer                   = "https://accounts.google.com"
    attributes_url                = "https://people.googleapis.com/v1/people/me?personFields="
    attributes_url_add_attributes = "true"
    authorize_url                 = "https://accounts.google.com/o/oauth2/v2/auth"
    token_url                     = "https://www.googleapis.com/oauth2/v4/token"
    token_request_method          = "POST"
  }

  # Map Google claims → Cognito user pool attributes.
  attribute_mapping = {
    email          = "email"
    email_verified = "email_verified"
    given_name     = "given_name"
    family_name    = "family_name"
    picture        = "picture"
    username       = "sub"
  }
}

###############################################################################
# Cognito App Client
###############################################################################

resource "aws_cognito_user_pool_client" "main" {
  name         = var.app_client_name
  user_pool_id = aws_cognito_user_pool.main.id

  # No client secret — suitable for public clients (SPAs, mobile apps).
  generate_secret = false

  # Token validity — free tier friendly, sensible defaults.
  access_token_validity  = 1   # hours
  id_token_validity      = 1   # hours
  refresh_token_validity = 30  # days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }

  # OAuth2 settings required for the Hosted UI + Google federation.
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]

  callback_urls = var.callback_urls
  logout_urls   = var.logout_urls

  # Allow both native Cognito login and Google federation.
  supported_identity_providers = [
    "COGNITO",
    aws_cognito_identity_provider.google.provider_name,
  ]

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",      # Secure Remote Password — recommended for login
    "ALLOW_REFRESH_TOKEN_AUTH", # Allow token refresh
  ]

  # Prevent user existence errors from leaking during auth.
  prevent_user_existence_errors = "ENABLED"

  depends_on = [aws_cognito_identity_provider.google]
}

###############################################################################
# Outputs
###############################################################################

output "user_pool_id" {
  description = "ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.endpoint
}

output "app_client_id" {
  description = "ID of the Cognito App Client."
  value       = aws_cognito_user_pool_client.main.id
}

output "hosted_ui_url" {
  description = "Cognito Hosted UI login URL."
  value       = "https://${var.cognito_domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.main.id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

output "google_idp_redirect_uri" {
  description = "Add this URI to your Google OAuth2 client's Authorized redirect URIs in Google Cloud Console."
  value       = "https://${var.cognito_domain}.auth.${var.aws_region}.amazoncognito.com/oauth2/idpresponse"
}

output "post_confirmation_lambda_arn" {
  description = "ARN of the post confirmation Lambda function."
  value       = aws_lambda_function.post_confirmation.arn
}
