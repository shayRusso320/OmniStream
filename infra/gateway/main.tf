###############################################################################
# API Gateway — core configuration
#
# This file owns only the gateway itself:
#   - HTTP API
#   - Cognito JWT authorizer
#   - Default stage + CloudWatch logging
#
# Each route and its integration lives in its own flow module under flows/.
# Flow modules receive api_id, execution_arn, and authorizer_id as inputs.
###############################################################################

###############################################################################
# Data Sources
###############################################################################

data "aws_region" "current" {}

###########################################################################
# API Gateway
###############################################################################

resource "aws_apigatewayv2_api" "main" {
  name          = var.api_name
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allowed_origins
    allow_methods = var.cors_allowed_methods
    allow_headers = var.cors_allowed_headers
    max_age       = var.cors_max_age
  }

  tags = merge(var.tags, { Name = var.api_name })
}

###############################################################################
# Cognito JWT Authorizer
###############################################################################

resource "aws_apigatewayv2_authorizer" "cognito_jwt" {
  api_id           = aws_apigatewayv2_api.main.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "cognito-jwt-authorizer"

  jwt_configuration {
    audience = [var.cognito_user_pool_client_id]
    issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_user_pool_id}"
  }
}

###############################################################################
# Stage + Logging
###############################################################################

resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${var.api_name}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      sourceIp         = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
      integrationError = "$context.integrationErrorMessage"
      authorizeError   = "$context.authorizer.error"
    })
  }

  tags = merge(var.tags, { Name = "${var.api_name}-default-stage" })
}
