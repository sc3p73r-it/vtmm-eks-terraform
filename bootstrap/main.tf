terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }

  # Bootstrap runs with a local backend because the S3 buckets it creates
  # are the backend for every environment.
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}

data "aws_caller_identity" "current" {}

# GitHub OIDC thumbprint derived from the published cert chain
data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.github.certificates[0].sha1_fingerprint]
}

# Terraform state buckets (one per environment)
resource "aws_s3_bucket" "tfstate" {
  for_each = toset(var.environments)

  bucket        = "${var.project}-tfstate-${each.value}-${var.region}"
  force_destroy = false

  tags = merge(var.tags, {
    Name        = "${var.project}-tfstate-${each.value}-${var.region}"
    Environment = each.value
  })
}

resource "aws_s3_bucket_versioning" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "tfstate" {
  for_each = aws_s3_bucket.tfstate

  bucket = each.value.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Shared DynamoDB lock table for all environments
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.project}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}

# GitHub Actions OIDC role allowing the repo to assume AWS permissions
data "aws_iam_policy_document" "github_assume_role_policy" {
  statement {
    effect = "Allow"

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

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "${var.project}-gha"
  assume_role_policy   = data.aws_iam_policy_document.github_assume_role_policy.json
  max_session_duration = 3600
  tags                 = var.tags
}

# Terraform state + infrastructure provisioning permissions
data "aws_iam_policy_document" "github_actions_policy" {
  statement {
    sid    = "TerraformState"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [
      for bucket in aws_s3_bucket.tfstate : bucket.arn
    ] # plus object-level below
  }

  statement {
    sid       = "TerraformStateObjects"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [for bucket in aws_s3_bucket.tfstate : "${bucket.arn}/*"]
  }

  statement {
    sid    = "TerraformStateLock"
    effect = "Allow"

    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
    ]

    resources = [aws_dynamodb_table.terraform_locks.arn]
  }

  statement {
    sid    = "Infrastructure"
    effect = "Allow"

    actions = [
      "ec2:*",
      "eks:*",
      "iam:*",
      "kms:*",
      "logs:*",
      "autoscaling:*",
      "elasticloadbalancing:*",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "terraform"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_policy.json
}