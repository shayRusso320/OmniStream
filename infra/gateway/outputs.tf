output "api_id" {
  description = "ID of the HTTP API — passed to every flow module."
  value       = aws_apigatewayv2_api.main.id
}

output "api_endpoint" {
  description = "Base invoke URL of the HTTP API."
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "execution_arn" {
  description = "Execution ARN of the HTTP API — used by Lambda permissions in flow modules."
  value       = aws_apigatewayv2_api.main.execution_arn
}

output "cognito_jwt_authorizer_id" {
  description = "ID of the Cognito JWT authorizer — passed to authenticated flow modules."
  value       = aws_apigatewayv2_authorizer.cognito_jwt.id
}
