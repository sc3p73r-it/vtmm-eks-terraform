variable "environment" {
  description = "Deployment environment: dev | uat | prod"
  type        = string

  validation {
    condition     = contains(["dev", "uat", "prod"], var.environment)
    error_message = "environment must be one of: dev, uat, prod."
  }
}

variable "region" {
  description = "AWS region to deploy to"
  type        = string
  default     = "ap-southeast-1"
}

variable "project" {
  description = "Project name used for resource naming"
  type        = string
  default     = "vtmm-eks"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "private_subnets" {
  description = "CIDR ranges for private subnets"
  type        = list(string)
}

variable "public_subnets" {
  description = "CIDR ranges for public subnets"
  type        = list(string)
}

variable "node_groups" {
  description = "Map of EKS managed node group configurations"
  type = map(object({
    desired_size   = number
    max_size       = number
    min_size       = number
    instance_types = list(string)
    capacity_type  = optional(string, "ON_DEMAND")
    labels         = map(string)
    taints         = map(string)
  }))
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}