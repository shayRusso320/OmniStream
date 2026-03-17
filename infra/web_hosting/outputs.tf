output "cloudfront_url" {
  description = "CloudFront distribution URL — use this as your app URL."
  value       = "https://${aws_cloudfront_distribution.app.domain_name}"
}

output "s3_bucket_name" {
  description = "S3 bucket name — deploy your build here."
  value       = aws_s3_bucket.app.id
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID — needed to invalidate cache after deploy."
  value       = aws_cloudfront_distribution.app.id
}

output "deploy_role_arn" {
  description = "Role ARN to set as AWS_DEPLOY_ROLE_ARN in GitHub Actions variables."
  value       = aws_iam_role.github_actions_deploy.arn
}