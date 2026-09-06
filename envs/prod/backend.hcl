bucket  = "vtmm-eks-tfstate-prod-ap-southeast-1"
key     = "prod/terraform.tfstate"
region  = "ap-southeast-1"
dynamodb_table = "vtmm-eks-terraform-locks"
encrypt = true