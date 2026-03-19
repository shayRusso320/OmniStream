###############################################################################
# Module: Database
###############################################################################

module "dynamodb" {
  source = "./infra/dynamodb"

  tags               = var.tags
  table_name         = "OmniStreamTable"
  billing_mode       = "PROVISIONED"
  read_capacity      = 5
  write_capacity     = 5
  enable_pitr        = false
  trigger_lambda_arn = ""
}


###############################################################################
# OIDC Provider for GitHub Actions
###############################################################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint — stable, does not need to change.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}


###############################################################################
# Module: Lambda artifacts and deployment infrastructure
###############################################################################
module "lambda_artifacts" {
  source = "./infra/lambda_artifacts"

  artifacts_bucket_name    = "omnistream-lambda-artifacts-123456" # Must be globally unique.
  github_functions_repo    = var.github_functions_repo
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn

  tags = var.tags
}


###############################################################################
# Module: Authentication
###############################################################################

module "cognito" {
  source = "./infra/cognito"

  tags                 = var.tags
  user_pool_name       = "OmniStreamUserPool"
  app_client_name      = "OmniStreamAppClient"
  cognito_domain       = "omni-stream-auth"
  google_client_id     = var.google_client_id
  google_client_secret = var.google_client_secret
  callback_urls        = [module.web_hosting.cloudfront_url]
  logout_urls          = [module.web_hosting.cloudfront_url]

  lambda_post_confirmation_arn  = module.register_user.post_confirmation_lambda_arn
  lambda_post_confirmation_name = module.register_user.post_confirmation_lambda_name
}


###############################################################################
# Module: Gateway
###############################################################################

module "api_gateway" {
  source = "./infra/gateway"

  tags                        = var.tags
  api_name                    = "omnistream-api"
  cognito_user_pool_id        = module.cognito.user_pool_id
  cognito_user_pool_client_id = module.cognito.app_client_id
  cors_allowed_origins        = [module.web_hosting.cloudfront_url]
  cors_allowed_methods        = ["GET", "POST", "OPTIONS"]
  cors_allowed_headers        = ["Authorization", "Content-Type"]
  lambda_routes = {
    add_user_topics = {
      route_key     = "POST /attach-topic-to-user"
      function_name = module.add_user_topics.lambda_function_name
      invoke_arn    = module.add_user_topics.lambda_invoke_arn
    }
  }

}


###############################################################################
# Module: Cloudfront + S3 for Web Hosting
###############################################################################

module "web_hosting" {
  source = "./infra/web_hosting"

  app_bucket_name = "omnistream-app-bucket-123456" # Must be globally unique.

  github_frontend_repo     = var.github_frontend_repo
  github_oidc_provider_arn = aws_iam_openid_connect_provider.github.arn
  tags                     = var.tags
}