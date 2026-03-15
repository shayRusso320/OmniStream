variable "api_name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "cognito_user_pool_id" {
  description = "ID of the Cognito User Pool (used by the JWT authorizer)."
  type        = string
}

variable "cognito_user_pool_client_id" {
  description = "App client ID of the Cognito User Pool (used by the JWT authorizer)."
  type        = string
}

variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "cors_allowed_origins" {
  description = "CORS allowed origins for the API Gateway."
  type        = list(string)
  default     = ["*"]
}

variable "cors_allowed_methods" {
  description = "CORS allowed HTTP methods for the API Gateway."
  type        = list(string)
}

variable "cors_allowed_headers" {
  description = "CORS allowed headers for the API Gateway."
  type        = list(string)
}

variable "cors_max_age" {
  description = "CORS max age in seconds for the API Gateway."
  type        = number
  default     = 300
}
