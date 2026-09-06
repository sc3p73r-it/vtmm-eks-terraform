output "state_buckets" {
  description = "Map of S3 state buckets by environment"
  value = {
    for env, bucket in aws_s3_bucket.tfstate : env => bucket.id
  }
}

output "lock_table" {
  description = "Name of the DynamoDB lock table"
  value       = aws_dynamodb_table.terraform_locks.id
}

output "github_oidc_role_arn" {
  description = "ARN of the GitHub Actions OIDC role"
  value       = aws_iam_role.github_actions.arn
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}