###############################################################################
# API Gateway — core configuration using Terraform module
#
# This module manages:
#   - HTTP API
#   - Cognito JWT authorizer
#   - Default stage + CloudWatch logging
#   - Routes and integrations
#
# Lambda integrations are defined via lambda_integrations variable.
###############################################################################

###############################################################################
# Data Sources
###############################################################################

data "aws_region" "current" {}

###############################################################################
# API Gateway Module
###############################################################################

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "~> 5.0"

  name          = var.api_name
  protocol_type = "HTTP"
  create_domain_name = false

  cors_configuration = {
    allow_origins = var.cors_allowed_origins
    allow_methods = var.cors_allowed_methods
    allow_headers = var.cors_allowed_headers
    max_age       = var.cors_max_age
  }

  # Access logs
  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 7
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

  # JWT Authorizer
  authorizers = {
    cognito_jwt = {
      authorizer_type  = "JWT"
      identity_sources = ["$request.header.Authorization"]
      name             = "cognito-jwt-authorizer"

      jwt_configuration = {
        audience = [var.cognito_user_pool_client_id]
        issuer   = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${var.cognito_user_pool_id}"
      }
    }
  }

  # Routes & Integration(s)
  routes = {
    for key, lambda in var.lambda_integrations : lambda.route_key => {
      integration = {
        type                   = "AWS_PROXY"
        uri                    = lambda.invoke_arn
        payload_format_version = "2.0"
      }
      authorizer_key = "cognito_jwt"
    }
  }

  tags = merge(var.tags, { Name = var.api_name })
}

###############################################################################
# Lambda Permissions for all integrations (required by AWS)
###############################################################################

resource "aws_lambda_permission" "apigw_invoke" {
  for_each = var.lambda_integrations

  statement_id  = "AllowAPIGWInvoke${replace(each.key, "-", "")}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${module.api_gateway.api_execution_arn}/*"
}
