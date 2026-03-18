variable "dynamodb_table_name" {
  description = "Name of the DynamoDB table."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "ARN of the DynamoDB table."
  type        = string
}

variable "openai_api_key" {
  description = "OpenAI API key for embedding model."
  type        = string
  sensitive   = true
}

variable "qdrant_url" {
  description = "Qdrant instance URL."
  type        = string
}

variable "qdrant_api_key" {
  description = "Qdrant API key."
  type        = string
  sensitive   = true
}

variable "qdrant_collection" {
  description = "Qdrant collection name for topic vectors."
  type        = string
  default     = "topics"
}

variable "artifacts_bucket_name" {
  description = "Name of the S3 bucket that holds Lambda artifacts."
  type        = string
}

variable "artifact_key" {
  description = "Key of the Lambda artifact in S3."
  type        = string
}

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
