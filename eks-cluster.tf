module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }

  cluster_enabled_log_types = [
    "audit",
    "api",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Core addons
  cluster_addons = merge(
    {
      coredns    = {}
      kube-proxy = {}
      vpc-cni = {
        most_recent = true
      }
      eks-pod-identity-agent = {
        most_recent = true
      }
    },
    var.enable_ebs_csi_driver ? {
      aws-ebs-csi-driver = {
        most_recent = true
      }
    } : {},
    var.enable_cloudwatch_observability ? {
      amazon-cloudwatch-observability = {
        most_recent = true
      }
    } : {},
    var.enable_efs_csi_driver ? {
      aws-efs-csi-driver = {
        most_recent = true
      }
    } : {}
  )

  # Cluster access entry
  # To add the current caller identity as an administrator
  enable_cluster_creator_admin_permissions = true

  authentication_mode = "API_AND_CONFIG_MAP" # Explicitly set authentication mode to avoid conflicts with the default value

  access_entries = {
    admin = {
      kubernetes_groups = ["eks-admin"]
      principal_arn     = aws_iam_role.admin_role.arn
      type              = "STANDARD"
      policy_associations = {
        admin = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
    developer = {
      kubernetes_groups = ["eks-developer-group"]
      principal_arn     = aws_iam_role.developer_role.arn
      type              = "STANDARD"
      policy_associations = {
        developer = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"
          access_scope = {
            type       = "namespace"
            namespaces = ["dev"]
          }
        }
      }
    }
    readonly = {
      kubernetes_groups = ["eks-readonly-group"]
      principal_arn     = aws_iam_role.readonly_role.arn
      type              = "STANDARD"
      policy_associations = {
        readonly = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSViewPolicy"
          access_scope = {
            type = "cluster"
          }
        }
      }
    }
  }

  eks_managed_node_group_defaults = {
    ami_type       = "AL2023_x86_64_STANDARD"
    instance_types = ["t3.small"]

    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    main = {
      min_size     = 1
      max_size     = 5
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = var.environment
        NodeGroup   = "initial"
        Purpose     = "bootstrap"
      }

      tags = merge(
        local.common_tags,
        {
          "k8s.io/cluster-autoscaler/enabled"                        = "true"
          "k8s.io/cluster-autoscaler/${var.cluster_name}"            = "owned"
          "k8s.io/cluster-autoscaler/node-template/resources/cpu"    = "2"
          "k8s.io/cluster-autoscaler/node-template/resources/memory" = "4Gi"
        }
      )
    }
  }

  tags = local.common_tags
}
