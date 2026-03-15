################### GENERAL VARIABLES ###################
variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "eu-north-1"
}

variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "dev"
  }
}

################### COGNITO VARIABLES ###################


variable "google_client_id" {
  description = "Google OAuth2 client ID."
  sensitive   = true
}

variable "google_client_secret" {
  description = "Google OAuth2 client secret."
  sensitive   = true
}

variable "callback_urls" {
  description = "List of allowed callback URLs."
  type        = list(string)
  default     = ["http://localhost:3000/callback"]
}

variable "logout_urls" {
  description = "List of allowed logout URLs."
  type        = list(string)
  default     = ["http://localhost:3000"]
}

##################### EXTERNAL API VARIABLES ###################
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