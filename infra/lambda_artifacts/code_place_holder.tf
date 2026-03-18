###############################################################################
# Terraform – Lambda Functions
#
# Bootstrap strategy:
#   A placeholder zip is created locally and uploaded to S3 once.
#   All Lambda functions reference this placeholder on first deploy.
#   The functions pipeline (omnistream-functions repo) owns the code
#   from that point on via lambda:UpdateFunctionCode.
#   ignore_changes on s3_key/s3_bucket/s3_object_version ensures
#   Terraform never overwrites what the functions pipeline deploys.
###############################################################################

locals {
  default_lambda_key = "placeholder/lambda.zip"
}

###############################################################################
# Placeholder zip — committed to infra repo, uploaded once to S3
###############################################################################

data "archive_file" "placeholder" {
  type        = "zip"
  output_path = "${path.module}/placeholder.zip"

  source {
    filename = "index.py"
    content  = "def handler(event, context): return {'statusCode': 200}"
  }
}

resource "aws_s3_object" "placeholder" {
  bucket = var.artifacts_bucket_name
  key    = local.default_lambda_key
  source = data.archive_file.placeholder.output_path
  etag   = data.archive_file.placeholder.output_md5
}

