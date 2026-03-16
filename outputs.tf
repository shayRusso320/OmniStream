output "hosted_ui_url" {
  description = "Cognito Hosted UI login URL."
  value       = "https://${module.cognito.cognito_domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${module.cognito.app_client_id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

output "app_client_id" {
  description = "ID of the Cognito App Client."
  value       = module.cognito.app_client_id
}

output "cloudfront_url" {
  description = "CloudFront distribution URL — use this as your app URL."
  value       = module.web_hosting.cloudfront_url
}