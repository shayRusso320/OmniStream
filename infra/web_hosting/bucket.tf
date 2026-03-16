resource "aws_s3_bucket" "app" {
  bucket = var.app_bucket_name
  tags   = merge(var.tags, { Name = var.app_bucket_name })
}

resource "aws_s3_bucket_public_access_block" "app" {
  bucket                  = aws_s3_bucket.app.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

