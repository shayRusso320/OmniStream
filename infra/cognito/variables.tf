variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

variable "user_pool_name" {
  description = "Name of the Cognito User Pool."
  type        = string
}

variable "app_client_name" {
  description = "Name of the Cognito User Pool App Client."
  type        = string
}

variable "cognito_domain" {
  description = "Domain prefix for the Cognito Hosted UI. Must be unique across all Cognito user pools in the region."
  type        = string
} 

variable "google_client_id"     {
  description = "Google OAuth2 client ID."
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth2 client secret."
  sensitive   = true
}

variable "callback_urls"        {
  description = "List of allowed callback URLs."
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls"          {
  description = "List of allowed logout URLs."
  type        = list(string)
  default     = ["http://localhost:3000"]
}

variable "lambda_post_confirmation_arn" {
  description = "ARN of the Lambda function to trigger after user confirmation."
  type        = string
}

variable "lambda_post_confirmation_name" {
  description = "Name of the Lambda function to trigger after user confirmation."
  type        = string
}