output "vpc_id" {
  description = "ID of the VPC"
  value       = length(module.vpc) > 0 ? module.vpc[0].vpc_id : null
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_name : null
}

output "cluster_endpoint" {
  description = "Endpoint for the EKS cluster API server"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_endpoint : null
}

output "cluster_certificate_authority" {
  description = "Base64 encoded certificate authority data"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_certificate_authority : null
}