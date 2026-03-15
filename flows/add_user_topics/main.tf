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

###############################################################################
# IAM
###############################################################################

data "aws_iam_policy_document" "attach_topic_lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "attach_topic_lambda" {
  name               = "attach-topic-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.attach_topic_lambda_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "attach_topic_basic_execution" {
  role       = aws_iam_role.attach_topic_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

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

resource "aws_iam_role_policy" "attach_topic_dynamodb" {
  name   = "attach-topic-dynamodb-policy"
  role   = aws_iam_role.attach_topic_lambda.id
  policy = data.aws_iam_policy_document.attach_topic_dynamodb.json
}

###############################################################################
# Lambda
###############################################################################

data "archive_file" "attach_topic_zip" {
  type        = "zip"
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_lambda_function" "attach_topic" {
  function_name    = "attach-topic-to-user"
  role             = aws_iam_role.attach_topic_lambda.arn
  runtime          = "python3.12"
  handler          = "index.handler"
  filename         = data.archive_file.attach_topic_zip.output_path
  source_code_hash = data.archive_file.attach_topic_zip.output_base64sha256
  memory_size      = 128
  timeout          = 30 # Extra time for OpenAI + Qdrant calls.

  environment {
    variables = {
      DYNAMODB_TABLE    = var.dynamodb_table_name
      OPENAI_API_KEY    = var.openai_api_key
      QDRANT_URL        = var.qdrant_url
      QDRANT_API_KEY    = var.qdrant_api_key
      QDRANT_COLLECTION = var.qdrant_collection
    }
  }

  tags = merge(var.tags, { Name = "attach-topic-to-user" })
}
