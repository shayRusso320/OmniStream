###############################################################################
# Flow — POST /attach-topic-to-user
#
# JWT authenticated. Triggers a Lambda that:
#   1. Checks if the topic already exists in DynamoDB
#   2. If new:
#      2.1 Embeds the topic name via OpenAI
#      2.2 Stores the vector in Qdrant, gets back a vector ID
#      2.3 Creates a Topic metadata row in DynamoDB
#   3. Always creates a user↔topic link row in DynamoDB
###############################################################################

locals {
  lambda_name = "attach-topic-to-user"
}

###############################################################################
# IAM
###############################################################################

data "aws_iam_policy_document" "attach_topic_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
    ]
    resources = [
      var.dynamodb_table_arn,
      "${var.dynamodb_table_arn}/index/*",
    ]
  }
}

###############################################################################
# Lambda
###############################################################################

module "attach_topic_lambda" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 7.0"

  function_name = local.lambda_name
  handler       = "index.handler"
  runtime       = "python3.14"
  source_path   = "${path.module}\\src" # folder with index.py + requirements.txt
  memory_size   = 128
  timeout       = 30

  environment_variables = {
    DYNAMODB_TABLE    = var.dynamodb_table_name
    OPENAI_API_KEY    = var.openai_api_key
    QDRANT_URL        = var.qdrant_url
    QDRANT_API_KEY    = var.qdrant_api_key
    QDRANT_COLLECTION = var.qdrant_collection
  }

  attach_policy_json = true
  policy_json        = data.aws_iam_policy_document.attach_topic_dynamodb.json

  tags = merge(var.tags, { Name = local.lambda_name })
}