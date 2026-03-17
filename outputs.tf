############ Cognito Outputs ############

output "hosted_ui_url" {
  description = "Cognito Hosted UI login URL."
  value       = "https://${module.cognito.cognito_domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${module.cognito.app_client_id}&response_type=code&scope=openid+email+profile&redirect_uri=${var.callback_urls[0]}"
}

output "user_pool_id" {
  description = "ID of the Cognito User Pool."
  value       = module.cognito.user_pool_id
}

output "app_client_id" {
  description = "ID of the Cognito App Client."
  value       = module.cognito.app_client_id
}

output "cognito_domain" {
  description = "Cognito domain prefix."
  value       = module.cognito.cognito_domain
}

############# CloudFront + web hosting Outputs ############
output "app_url" {
  description = "CloudFront distribution URL — use this as your app URL."
  value       = module.web_hosting.cloudfront_url
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution."
  value       = module.web_hosting.cloudfront_distribution_id
}

output "s3_bucket_name" {
  description = "Name of the S3 frontend bucket."
  value       = module.web_hosting.s3_bucket_name
}

output "deploy_role_arn" {
  description = "Role ARN to set as AWS_DEPLOY_ROLE_ARN in GitHub Actions variables."
  value       = module.web_hosting.deploy_role_arn
}

############# Gateway Outputs ############
output "api_url" {
  description = "API Gateway URL — use this as your API endpoint."
  value       = module.api_gateway.api_endpoint
}

