region      = "ap-southeast-1"
environment = "dev"
project     = "vtmm-eks"

cluster_version = "1.35"


vpc_cidr        = "10.0.0.0/16"
private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

node_groups = {
  general = {
    desired_size   = 2
    min_size       = 1
    max_size       = 3
    instance_types = ["t3.medium"]
    labels = {
      role = "general"
    }
    taints = {}
  }
}

tags = {
  Environment = "dev"
  Project     = "vtmm-eks"
  ManagedBy   = "Terraform"
}