terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Remote state lives in per-environment S3 buckets, configured at runtime via
  # `terraform init -backend-config=envs/<env>/backend.hcl`. Additional S3
  # backend attributes (dynamodb_table, use_lockfile, ...) are supplied the same
  # way, so only static constraints belong in this file.
  backend "s3" {}
}

provider "aws" {
  region = var.region

  default_tags {
    tags = var.tags
  }
}