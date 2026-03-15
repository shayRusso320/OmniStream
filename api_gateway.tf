# ###############################################################################
# # Terraform – API Gateway (HTTP API v2)
# #
# # Routes:
# #   POST /attach-topic-to-user  → Lambda (Cognito JWT auth)
# #   POST /detach-topic-to-user  → Lambda (Cognito JWT auth)
# #   GET  /user-topics           → Lambda (Cognito JWT auth)
# #   POST /news                  → SQS    (no auth for now — revisit later)
# ###############################################################################

# ###############################################################################
# # Variables
# ###############################################################################

# variable "api_name" {
#   description = "Name of the HTTP API."
#   type        = string
#   default     = "omnystream-api"
# }

# variable "news_queue_name" {
#   description = "Name of the SQS queue that receives incoming news events."
#   type        = string
#   default     = "incoming-news-queue"
# }

# ###############################################################################
# # SQS Queue — incoming news
# ###############################################################################

# resource "aws_sqs_queue" "news" {
#   name                       = var.news_queue_name
#   message_retention_seconds  = 3600 # 1 hour
#   visibility_timeout_seconds = 30

#   tags = merge(var.tags, { Name = var.news_queue_name })
# }

# ###############################################################################
# # IAM — allow API Gateway to send messages to SQS
# ###############################################################################

# data "aws_iam_policy_document" "apigw_sqs_assume" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]

#     principals {
#       type        = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }
#   }
# }

# resource "aws_iam_role" "apigw_sqs" {
#   name               = "apigw-sqs-role"
#   assume_role_policy = data.aws_iam_policy_document.apigw_sqs_assume.json
#   tags               = var.tags
# }

# data "aws_iam_policy_document" "apigw_sqs_send" {
#   statement {
#     effect    = "Allow"
#     actions   = ["sqs:SendMessage"]
#     resources = [aws_sqs_queue.news.arn]
#   }
# }

# resource "aws_iam_role_policy" "apigw_sqs_send" {
#   name   = "apigw-sqs-send-policy"
#   role   = aws_iam_role.apigw_sqs.id
#   policy = data.aws_iam_policy_document.apigw_sqs_send.json
# }

# ###############################################################################
# # IAM — Lambda execution role for user-facing Lambdas
# ###############################################################################


# resource "aws_iam_role" "user_lambda" {
#   name               = "user-lambda-role"
#   assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
#   tags               = var.tags
# }

# resource "aws_iam_role_policy_attachment" "user_lambda_basic_execution" {
#   role       = aws_iam_role.user_lambda.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
# }

# data "aws_iam_policy_document" "user_lambda_dynamodb" {
#   statement {
#     effect = "Allow"
#     actions = [
#       "dynamodb:PutItem",
#       "dynamodb:UpdateItem",
#       "dynamodb:DeleteItem",
#       "dynamodb:GetItem",
#       "dynamodb:Query",
#     ]
#     resources = [
#       aws_dynamodb_table.main.arn,
#       "${aws_dynamodb_table.main.arn}/index/*",
#     ]
#   }
# }

# resource "aws_iam_role_policy" "user_lambda_dynamodb" {
#   name   = "user-lambda-dynamodb-policy"
#   role   = aws_iam_role.user_lambda.id
#   policy = data.aws_iam_policy_document.user_lambda_dynamodb.json
# }

# ###############################################################################
# # Placeholder Lambdas for user routes
# # Replace with real packages when ready.
# ###############################################################################

# data "archive_file" "attach_topic_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambdas/attach_topic/index.py"
#   output_path = "${path.module}/lambdas/attach_topic/lambda.zip"
# }

# resource "aws_lambda_function" "attach_topic" {
#   function_name    = "attach-topic-to-user"
#   role             = aws_iam_role.user_lambda.arn
#   runtime          = "python3.12"
#   handler          = "index.handler"
#   filename         = data.archive_file.attach_topic_zip.output_path
#   source_code_hash = data.archive_file.attach_topic_zip.output_base64sha256
#   memory_size      = 128
#   timeout          = 10

#   environment {
#     variables = { DYNAMODB_TABLE = aws_dynamodb_table.main.name }
#   }

#   tags = merge(var.tags, { Name = "attach-topic-to-user" })
# }

# data "archive_file" "detach_topic_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambdas/detach_topic/index.py"
#   output_path = "${path.module}/lambdas/detach_topic/lambda.zip"
# }

# resource "aws_lambda_function" "detach_topic" {
#   function_name    = "detach-topic-from-user"
#   role             = aws_iam_role.user_lambda.arn
#   runtime          = "python3.12"
#   handler          = "index.handler"
#   filename         = data.archive_file.detach_topic_zip.output_path
#   source_code_hash = data.archive_file.detach_topic_zip.output_base64sha256
#   memory_size      = 128
#   timeout          = 10

#   environment {
#     variables = { DYNAMODB_TABLE = aws_dynamodb_table.main.name }
#   }

#   tags = merge(var.tags, { Name = "detach-topic-from-user" })
# }

# data "archive_file" "user_topics_zip" {
#   type        = "zip"
#   source_file = "${path.module}/lambdas/user_topics/index.py"
#   output_path = "${path.module}/lambdas/user_topics/lambda.zip"
# }

# resource "aws_lambda_function" "user_topics" {
#   function_name    = "get-user-topics"
#   role             = aws_iam_role.user_lambda.arn
#   runtime          = "python3.12"
#   handler          = "index.handler"
#   filename         = data.archive_file.user_topics_zip.output_path
#   source_code_hash = data.archive_file.user_topics_zip.output_base64sha256
#   memory_size      = 128
#   timeout          = 10

#   environment {
#     variables = { DYNAMODB_TABLE = aws_dynamodb_table.main.name }
#   }

#   tags = merge(var.tags, { Name = "get-user-topics" })
# }

# # Allow API Gateway to invoke each user Lambda.
# resource "aws_lambda_permission" "apigw_attach_topic" {
#   statement_id  = "AllowAPIGWInvokeAttachTopic"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.attach_topic.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*"
# }

# resource "aws_lambda_permission" "apigw_detach_topic" {
#   statement_id  = "AllowAPIGWInvokeDetachTopic"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.detach_topic.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*"
# }

# resource "aws_lambda_permission" "apigw_user_topics" {
#   statement_id  = "AllowAPIGWInvokeUserTopics"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.user_topics.function_name
#   principal     = "apigateway.amazonaws.com"
#   source_arn    = "${aws_apigatewayv2_api.main.execution_arn}/*"
# }

# ###############################################################################
# # HTTP API
# ###############################################################################

# resource "aws_apigatewayv2_api" "main" {
#   name          = var.api_name
#   protocol_type = "HTTP"

#   cors_configuration {
#     allow_origins = ["*"] # Tighten to your domain in production.
#     allow_methods = ["GET", "POST", "OPTIONS"]
#     allow_headers = ["Authorization", "Content-Type"]
#     max_age       = 300
#   }

#   tags = merge(var.tags, { Name = var.api_name })
# }

# ###############################################################################
# # Cognito JWT Authorizer
# ###############################################################################

# resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
#   api_id           = aws_apigatewayv2_api.main.id
#   authorizer_type  = "JWT"
#   identity_sources = ["$request.header.Authorization"]
#   name             = "cognito-jwt-authorizer"

#   jwt_configuration {
#     audience = [var.cognito_user_pool_client_id]
#     issuer   = "https://cognito-idp.${var.aws_region}.amazonaws.com/${var.cognito_user_pool_id}"
#   }
# }

# ###############################################################################
# # Integrations
# ###############################################################################

# resource "aws_apigatewayv2_integration" "attach_topic" {
#   api_id                 = aws_apigatewayv2_api.main.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.attach_topic.invoke_arn
#   payload_format_version = "2.0"
# }

# resource "aws_apigatewayv2_integration" "detach_topic" {
#   api_id                 = aws_apigatewayv2_api.main.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.detach_topic.invoke_arn
#   payload_format_version = "2.0"
# }

# resource "aws_apigatewayv2_integration" "user_topics" {
#   api_id                 = aws_apigatewayv2_api.main.id
#   integration_type       = "AWS_PROXY"
#   integration_uri        = aws_lambda_function.user_topics.invoke_arn
#   payload_format_version = "2.0"
# }

# # SQS direct integration — no auth for now, will be revisited.
# resource "aws_apigatewayv2_integration" "news_sqs" {
#   api_id              = aws_apigatewayv2_api.main.id
#   integration_type    = "AWS_PROXY"
#   integration_subtype = "SQS-SendMessage"
#   credentials_arn     = aws_iam_role.apigw_sqs.arn

#   request_parameters = {
#     "QueueUrl"    = aws_sqs_queue.news.url
#     "MessageBody" = "$request.body"
#   }

#   payload_format_version = "1.0"
# }

# ###############################################################################
# # Routes
# ###############################################################################

# resource "aws_apigatewayv2_route" "attach_topic" {
#   api_id             = aws_apigatewayv2_api.main.id
#   route_key          = "POST /attach-topic-to-user"
#   target             = "integrations/${aws_apigatewayv2_integration.attach_topic.id}"
#   authorization_type = "JWT"
#   authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
# }

# resource "aws_apigatewayv2_route" "detach_topic" {
#   api_id             = aws_apigatewayv2_api.main.id
#   route_key          = "POST /detach-topic-to-user"
#   target             = "integrations/${aws_apigatewayv2_integration.detach_topic.id}"
#   authorization_type = "JWT"
#   authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
# }

# resource "aws_apigatewayv2_route" "user_topics" {
#   api_id             = aws_apigatewayv2_api.main.id
#   route_key          = "GET /user-topics"
#   target             = "integrations/${aws_apigatewayv2_integration.user_topics.id}"
#   authorization_type = "JWT"
#   authorizer_id      = aws_apigatewayv2_authorizer.cognito_jwt.id
# }

# resource "aws_apigatewayv2_route" "news" {
#   api_id             = aws_apigatewayv2_api.main.id
#   route_key          = "POST /news"
#   target             = "integrations/${aws_apigatewayv2_integration.news_sqs.id}"
#   authorization_type = "NONE"
# }

# ###############################################################################
# # Stage
# ###############################################################################

# resource "aws_apigatewayv2_stage" "default" {
#   api_id      = aws_apigatewayv2_api.main.id
#   name        = "$default"
#   auto_deploy = true

#   access_log_settings {
#     destination_arn = aws_cloudwatch_log_group.apigw.arn
#   }

#   tags = merge(var.tags, { Name = "${var.api_name}-default-stage" })
# }

# resource "aws_cloudwatch_log_group" "apigw" {
#   name              = "/aws/apigateway/${var.api_name}"
#   retention_in_days = 7

#   tags = var.tags
# }

# ###############################################################################
# # Outputs
# ###############################################################################

# output "api_endpoint" {
#   description = "Base URL of the HTTP API."
#   value       = aws_apigatewayv2_stage.default.invoke_url
# }

# output "news_queue_url" {
#   description = "URL of the SQS queue receiving incoming news."
#   value       = aws_sqs_queue.news.url
# }

# output "news_queue_arn" {
#   description = "ARN of the SQS queue receiving incoming news."
#   value       = aws_sqs_queue.news.arn
# }

# output "attach_topic_lambda_arn" {
#   description = "ARN of the attach-topic Lambda."
#   value       = aws_lambda_function.attach_topic.arn
# }

# output "detach_topic_lambda_arn" {
#   description = "ARN of the detach-topic Lambda."
#   value       = aws_lambda_function.detach_topic.arn
# }

# output "user_topics_lambda_arn" {
#   description = "ARN of the get-user-topics Lambda."
#   value       = aws_lambda_function.user_topics.arn
# }
