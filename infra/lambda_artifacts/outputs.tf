output "artifacts_bucket_name" {
  description = "S3 artifacts bucket name — set as ARTIFACTS_BUCKET in GitHub variables."
  value       = aws_s3_bucket.artifacts.id
}

output "functions_deploy_role_arn" {
  description = "Deploy role ARN — set as AWS_DEPLOY_ROLE_ARN in GitHub variables."
  value       = aws_iam_role.functions_deploy.arn
}

output "artifact_bucket_name" {
  description = "S3 artifact bucket name — set as ARTIFACTS_BUCKET in GitHub variables."
  value       = aws_s3_bucket.artifacts.id
}

output "artifact_key" {
  description = "S3 artifact key — set as ARTIFACT_KEY in GitHub variables."
  value       = local.default_lambda_key
}