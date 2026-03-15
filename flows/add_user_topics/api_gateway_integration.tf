resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGWInvokeAttachTopic"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.attach_topic.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*"
}

resource "aws_apigatewayv2_integration" "attach_topic_to_user" {
  api_id                 = var.api_gateway_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.attach_topic.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "attach_topic_to_user" {
  api_id             = var.api_gateway_id
  route_key          = "POST /attach-topic-to-user"
  target             = "integrations/${aws_apigatewayv2_integration.attach_topic_to_user.id}"
  authorization_type = "JWT"
  authorizer_id      = var.cognito_jwt_authorizer_id
}