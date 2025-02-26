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

provider "aws" {
  region = "us-east-1"
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

provider "kubectl" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  load_config_file       = false

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

module "eks" {
  source = "../../"

  environment     = "prod"
  cluster_name    = "module-test"
  cluster_version = 1.32

  vpc_cidr = "10.0.0.0/16"

  tags = {
    Team    = "platform"
    Project = "kubernetes-platform"
  }

  accountable = "devops team"
  git_repo    = "https://github.com/company/ecommerce-platform"

  enable_ebs_csi_driver = true

  # Auto Scaling Configuration (just one can be enabled)
  enable_karpenter          = false
  enable_cluster_autoscaler = true

  # Monitoring and Observability  (just one can be enabled)
  enable_prometheus_stack         = true
  enable_cloudwatch_observability = false

  # Prometheus Stack Configuration
  prometheus_storage_size   = "20Gi"
  prometheus_retention      = "7d"
  grafana_storage_size      = "5Gi"
  alertmanager_storage_size = "2Gi"

  # For production use, use a secure password
  # enable_prometheus_ingress   = true
  # grafana_admin_password      = var.grafana_admin_password

}