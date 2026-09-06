variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC to place the cluster in"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of the private subnets for the control plane and node groups"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    desired_size   = number
    min_size       = number
    max_size       = number
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = map(string)
    taints         = map(string)
  }))
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}