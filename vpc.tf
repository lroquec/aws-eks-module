module "vpc" {
  source       = "git::https://github.com/lroquec/aws-vpc-module.git//?ref=27a3710066d6b1db6d725eb768cbe24e14ec44f7" # commit hash of version v2.0.1
  environment  = var.environment
  project_name = var.name_prefix
  accountable  = var.accountable
  git_repo     = var.git_repo

  vpc_cidr = var.vpc_cidr

  create_public_subnets      = true
  create_private_subnets     = true
  create_database_subnets    = false
  create_elasticache_subnets = false
  enable_flow_log            = false

  private_subnet_tags = merge(
    {
      "kubernetes.io/role/internal-elb" = "1"
      "kubernetes.io/role"              = "private"
      "karpenter.sh/discovery"          = var.cluster_name
    }
  )

  custom_ports = {
    22  = "139.47.126.204/32"
    80  = "0.0.0.0/0"
    443 = "0.0.0.0/0"
  }

  tags = local.common_tags
}
