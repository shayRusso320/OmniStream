variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

variable "table_name" {
  description = "Name of the DynamoDB table."
  type        = string
  default     = "OmniStreamTable"
}

variable "billing_mode" {
  description = "PAY_PER_REQUEST (on-demand) or PROVISIONED. PROVISIONED is required for AWS Free Tier."
  type        = string
  default     = "PROVISIONED"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.billing_mode)
    error_message = "billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "read_capacity" {
  description = "Read capacity units. Free tier includes 25 RCU/month shared across all tables. 5 is sufficient for low throughput."
  type        = number
  default     = 5
}

variable "write_capacity" {
  description = "Write capacity units. Free tier includes 25 WCU/month shared across all tables. 5 is sufficient for low throughput."
  type        = number
  default     = 5
}

variable "enable_pitr" {
  description = "Whether to enable Point-in-Time Recovery."
  type        = bool
  default     = false
}

variable "trigger_lambda_arn" {
  description = "ARN of the Lambda function that consumes the DynamoDB stream. Leave empty to skip creating the event-source mapping."
  type        = string
  default     = ""
}