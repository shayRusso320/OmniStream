###############################################################################
# CloudFront Origin Access Control
###############################################################################

resource "aws_cloudfront_origin_access_control" "app" {
  name                              = "${var.app_bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

###############################################################################
# S3 Bucket Policy — allow only CloudFront to read
###############################################################################

data "aws_iam_policy_document" "app_bucket_policy" {
  statement {
    effect  = "Allow"
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.app.arn}",
      "${aws_s3_bucket.app.arn}/*"
    ]

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.app.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "app" {
  bucket = aws_s3_bucket.app.id
  policy = data.aws_iam_policy_document.app_bucket_policy.json
}