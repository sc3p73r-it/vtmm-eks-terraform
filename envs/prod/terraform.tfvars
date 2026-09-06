region      = "ap-southeast-1"
environment = "prod"
project     = "vtmm-eks"

cluster_version = "1.35"


vpc_cidr        = "10.2.0.0/16"
private_subnets = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
public_subnets  = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

node_groups = {
  general = {
    desired_size   = 3
    min_size       = 2
    max_size       = 6
    instance_types = ["t3.xlarge"]
    labels = {
      role = "general"
    }
    taints = {}
  }
  spot = {
    desired_size   = 2
    min_size       = 1
    max_size       = 4
    capacity_type  = "SPOT"
    instance_types = ["t3.large", "t3.xlarge"]
    labels = {
      role = "spot"
    }
    taints = {}
  }
}

tags = {
  Environment = "prod"
  Project     = "vtmm-eks"
  ManagedBy   = "Terraform"
}