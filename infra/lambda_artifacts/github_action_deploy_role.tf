###############################################################################
# Terraform – Lambda Artifacts S3 Bucket + GitHub Actions Deploy Role
#
# The OIDC provider is assumed to already exist in the account.
# The deploy role allows the functions repo workflow to:
#   - Upload artifacts to S3
#   - Update Lambda function code
###############################################################################

data "aws_region" "current" {}

###############################################################################
# GitHub Actions Deploy Role
###############################################################################
data "aws_iam_policy_document" "functions_deploy_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.github_oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_functions_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "functions_deploy" {
  name               = "github-actions-functions-deploy"
  assume_role_policy = data.aws_iam_policy_document.functions_deploy_assume.json
  tags               = var.tags
}

data "aws_iam_policy_document" "functions_deploy" {
  # Upload artifacts to S3
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = ["${aws_s3_bucket.artifacts.arn}/*"]
  }

  # Update Lambda function code
  statement {
    effect = "Allow"
    actions = [
      "lambda:UpdateFunctionCode",
    ]
    resources = ["arn:aws:lambda:${data.aws_region.current.name}:*:function:*"]
  }
}

resource "aws_iam_role_policy" "functions_deploy" {
  name   = "github-actions-functions-deploy-policy"
  role   = aws_iam_role.functions_deploy.id
  policy = data.aws_iam_policy_document.functions_deploy.json
}
