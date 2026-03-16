terraform {
  backend "s3" {
    bucket         = "omnistream-tf-state"
    key            = "global/terraform.tfstate"
    region         = "eu-north-1"
    dynamodb_table = "dynamo-tf-locks"
    encrypt        = true
  }
}