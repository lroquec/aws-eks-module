provider "aws" {
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

module "eks" {
  source = "../../"

  environment     = "prod"
  cluster_name    = "module-test"
  cluster_version = 1.31

  vpc_cidr = "10.0.0.0/16"

  # instance_types = ["t3.medium"]
  # min_size       = 1
  # max_size       = 2
  # desired_size   = 1
  # capacity_type  = "SPOT" # Using SPOT instances

  tags = {
    Team    = "platform"
    Project = "kubernetes-platform"
  }

  accountable = "devops team"
  git_repo    = "https://github.com/company/ecommerce-platform"

  enable_ebs_csi_driver = true
  enable_karpenter = true

}