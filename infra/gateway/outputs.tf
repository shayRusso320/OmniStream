output "api_id" {
  description = "ID of the HTTP API — passed to every flow module."
  value       = module.api_gateway.api_id
}

output "api_endpoint" {
  description = "Base invoke URL of the HTTP API."
  value       = module.api_gateway.api_endpoint
}

output "execution_arn" {
  description = "Execution ARN of the HTTP API — used by Lambda permissions in flow modules."
  value       = module.api_gateway.api_execution_arn
}

output "cognito_jwt_authorizer_id" {
  description = "ID of the Cognito JWT authorizer — passed to authenticated flow modules."
  value       = module.api_gateway.authorizers.cognito_jwt.id
}
