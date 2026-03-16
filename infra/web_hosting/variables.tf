variable "tags" {
  description = "Common tags applied to every resource."
  type        = map(string)
  default     = {}
}

variable "app_bucket_name" {
  description = "Globally unique S3 bucket name for the frontend app."
  type        = string
}

variable "cloudfront_price_class" {
  description = "CloudFront price class to use. PriceClass_100 is the cheapest option."
  type        = string
  default = "PriceClass_100"  # US/EU only — cheapest option.
}

variable "cloudfront_default_root_object" {
  description = "Default root object for CloudFront distribution."
  type        = string
  default     = "index.html"
}