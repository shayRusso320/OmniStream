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

################### WEB HOSTING VARIABLES ###################
variable "github_frontend_repo" {
  description = "GitHub repo containing frontend, including github action for CD."
  type        = string
}

################### LAMBDA ARTIFACTS VARIABLES ###################
variable "github_functions_repo" {
  description = "GitHub repo for Lambda functions in org/repo format e.g. myuser/omnistream-functions."
  type        = string
}