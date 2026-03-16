output "user_pool_id" {
  description = "ID of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "ARN of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.arn
}

output "user_pool_endpoint" {
  description = "Endpoint of the Cognito User Pool."
  value       = aws_cognito_user_pool.main.endpoint
}

output "app_client_id" {
  description = "ID of the Cognito App Client."
  value       = aws_cognito_user_pool_client.main.id
}

output "hosted_ui_url" {
  description = "Cognito Hosted UI login URL."
  value       = "https://${var.cognito_domain}.auth.${data.aws_region.current.name}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.main.id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

output "google_idp_redirect_uri" {
  description = "Add this URI to your Google OAuth2 client's Authorized redirect URIs in Google Cloud Console."
  value       = "https://${var.cognito_domain}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/idpresponse"
}

output "cognito_domain" {
  description = "Cognito domain prefix (used in Hosted UI URL and Google IdP redirect URI)."
  value       = var.cognito_domain
}