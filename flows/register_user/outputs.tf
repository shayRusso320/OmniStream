output "post_confirmation_lambda_arn" {
  description = "ARN of the post confirmation Lambda function."
  value       = module.post_confirmation_lambda.lambda_function_arn
}

output "post_confirmation_lambda_name" {
  description = "Name of the post confirmation Lambda function."
  value       = module.post_confirmation_lambda.lambda_function_name
}