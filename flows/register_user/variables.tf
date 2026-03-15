variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

variable "table_name" {
  description = "Name of the DynamoDB table that holds user information."
  type        = string
}

variable "table_arn" {
  description = "ARN of the DynamoDB table that holds user information."
  type        = string
}