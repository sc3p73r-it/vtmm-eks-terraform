output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data"
  value       = aws_eks_cluster.this.certificate_authority[0].data
}

output "cluster_security_group_id" {
  description = "ID of the security group attached to the cluster"
  value       = aws_security_group.eks_cluster.id
}

output "cluster_role_arn" {
  description = "ARN of the cluster IAM role"
  value       = aws_iam_role.eks.arn
}

output "node_role_arn" {
  description = "ARN of the node group IAM role"
  value       = aws_iam_role.node.arn
}