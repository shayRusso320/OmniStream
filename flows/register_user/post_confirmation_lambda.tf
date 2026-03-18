###############################################################################
# IAM Policy for DynamoDB Access
###############################################################################

data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:UpdateItem",
    ]
    resources = [
      var.table_arn,
      "${var.table_arn}/index/*", # Allow writes to GSI if needed
    ]
  }
}

###############################################################################
# Post Confirmation Lambda
###############################################################################

locals {
  lambda_name = "cognito-post-confirmation"
}

module "post_confirmation_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = local.lambda_name
  handler       = "index.handler"
  runtime       = "python3.12"

  create_package          = false
  ignore_source_code_hash = true

  s3_existing_package = {
    bucket = var.artifacts_bucket_name
    key    = var.artifact_key
  }

  environment_variables = {
    DYNAMODB_TABLE = var.table_name
  }

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.lambda_dynamodb.json

  tags = merge(var.tags, { Name = local.lambda_name })
}