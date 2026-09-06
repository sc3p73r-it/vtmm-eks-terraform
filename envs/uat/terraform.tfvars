region      = "ap-southeast-1"
environment = "uat"
project     = "vtmm-eks"

cluster_version = "1.35"


vpc_cidr        = "10.1.0.0/16"
private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
public_subnets  = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

node_groups = {
  general = {
    desired_size   = 2
    min_size       = 2
    max_size       = 4
    instance_types = ["t3.large"]
    labels = {
      role = "general"
    }
    taints = {}
  }
}

tags = {
  Environment = "uat"
  Project     = "vtmm-eks"
  ManagedBy   = "Terraform"
}