module "vpc" {
  source          = "./modules/vpc"
  project         = var.project
  environment     = var.environment
  region          = var.region
  vpc_cidr        = var.vpc_cidr
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets
  tags            = var.tags
}

module "eks" {
  source             = "./modules/eks"
  project            = var.project
  environment        = var.environment
  region             = var.region
  cluster_version    = var.cluster_version
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  node_groups        = var.node_groups
  tags               = var.tags
}