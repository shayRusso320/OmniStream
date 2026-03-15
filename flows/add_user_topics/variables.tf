variable "api_gateway_id" {
  description = "ID of the HTTP API Gateway."
  type        = string
}

variable "api_gateway_execution_arn" {
  description = "Execution ARN of the HTTP API Gateway — used for Lambda permission."
  type        = string
}

variable "cognito_jwt_authorizer_id" {
  description = "ID of the Cognito JWT authorizer."
  type        = string
}

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

variable "tags" {
  description = "Common tags."
  type        = map(string)
  default     = {}
}
