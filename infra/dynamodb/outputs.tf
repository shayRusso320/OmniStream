output "table_name" {
  description = "Name of the DynamoDB table."
  value       = aws_dynamodb_table.main.name
}

output "table_arn" {
  description = "ARN of the DynamoDB table."
  value       = aws_dynamodb_table.main.arn
}

output "stream_arn" {
  description = "ARN of the DynamoDB stream (pass to var.lambda_arn when ready)."
  value       = aws_dynamodb_table.main.stream_arn
}

output "gsi_name" {
  description = "Name of the Global Secondary Index."
  value       = "GSI-SK-PK"
}