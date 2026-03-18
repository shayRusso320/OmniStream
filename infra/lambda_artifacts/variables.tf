variable "artifacts_bucket_name" {
  description = "Globally unique S3 bucket name for Lambda artifacts."
  type        = string
}

variable "github_functions_repo" {
  description = "GitHub repo for Lambda functions in org/repo format e.g. myuser/omnistream-functions."
  type        = string
}

variable "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider registered in AWS. Only needs to exist once per AWS account."
  type        = string
}

variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default     = {}
}