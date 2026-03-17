###############################################################################
# Terraform – GitHub Actions OIDC IAM Role
#
# Allows GitHub Actions to deploy to S3 and invalidate CloudFront
# without any static credentials. Only the specified repo + branch
# can assume this role.
###############################################################################



###############################################################################
# OIDC Provider — register GitHub as a trusted identity provider in AWS.
# Only needs to exist once per AWS account. If it already exists, import it:
#   terraform import aws_iam_openid_connect_provider.github \
#     arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com
###############################################################################

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]

  # GitHub's OIDC thumbprint — stable, does not need to change.
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

###############################################################################
# IAM Role — assumed by GitHub Actions via OIDC
###############################################################################

data "aws_iam_policy_document" "github_actions_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    # Only allow the main branch of your specific repo to assume this role.
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions_deploy" {
  name               = "github-actions-frontend-deploy"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume.json
  tags               = var.tags
}

###############################################################################
# IAM Policy — minimal permissions, only what the workflow needs
###############################################################################

data "aws_iam_policy_document" "github_actions_deploy" {
  # S3 — sync dist/ to the bucket
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.app.arn}",
      "${aws_s3_bucket.app.arn}/*"
    ]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.app.arn]
  }

  # CloudFront — invalidate cache after deploy
  statement {
    effect    = "Allow"
    actions   = ["cloudfront:CreateInvalidation"]
    resources = [aws_cloudfront_distribution.app.arn]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "github-actions-frontend-deploy-policy"
  role   = aws_iam_role.github_actions_deploy.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}
