output "lambda_arn" {
  description = "ARN of the attach-topic Lambda."
  value       = module.attach_topic_lambda.lambda_function_arn
}

output "lambda_function_name" {
  description = "Name of the attach-topic Lambda."
  value       = module.attach_topic_lambda.lambda_function_name
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the attach-topic Lambda — used in API Gateway integration."
  value       = module.attach_topic_lambda.lambda_function_invoke_arn
}
