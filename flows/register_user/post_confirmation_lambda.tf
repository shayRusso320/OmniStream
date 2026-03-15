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
      var.table_arn,
      "${var.table_arn}/index/*", # Allow writes to GSI if needed
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
  source_file = "${path.module}/index.py"
  output_path = "${path.module}/lambda.zip"
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
      DYNAMODB_TABLE = var.table_name
    }
  }

  tags = merge(var.tags, { Name = "cognito-post-confirmation" })
}