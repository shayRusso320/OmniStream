output "lambda_arn" {
  description = "ARN of the attach-topic Lambda."
  value       = aws_lambda_function.attach_topic.arn
}

output "lambda_function_name" {
  description = "Name of the attach-topic Lambda."
  value       = aws_lambda_function.attach_topic.function_name
}
