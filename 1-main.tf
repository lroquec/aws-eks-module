data "aws_caller_identity" "current" {}

locals {
  admin_role_name     = "${var.name_prefix}-admin"
  developer_role_name = "${var.name_prefix}-developer"
  readonly_role_name  = "${var.name_prefix}-readonly"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

# Admin Role and Group
resource "aws_iam_role" "admin_role" {
  name = local.admin_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "admin_policy" {
  name = "${local.admin_role_name}-policy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:*",
          "iam:ListRoles",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group" "admin_group" {
  name = "${local.admin_role_name}-group"
  path = "/"
}

resource "aws_iam_group_policy" "admin_group_policy" {
  name  = "${local.admin_role_name}-group-policy"
  group = aws_iam_group.admin_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = aws_iam_role.admin_role.arn
      }
    ]
  })
}

# Developer Role and Group
resource "aws_iam_role" "developer_role" {
  name = local.developer_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "developer_policy" {
  name = "${local.developer_role_name}-policy"
  role = aws_iam_role.developer_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi",
          "iam:ListRoles",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group" "developer_group" {
  name = "${local.developer_role_name}-group"
  path = "/"
}

resource "aws_iam_group_policy" "developer_group_policy" {
  name  = "${local.developer_role_name}-group-policy"
  group = aws_iam_group.developer_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = aws_iam_role.developer_role.arn
      }
    ]
  })
}

# Readonly Role and Group
resource "aws_iam_role" "readonly_role" {
  name = local.readonly_role_name

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "readonly_policy" {
  name = "${local.readonly_role_name}-policy"
  role = aws_iam_role.readonly_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups",
          "eks:AccessKubernetesApi",
          "iam:ListRoles",
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group" "readonly_group" {
  name = "${local.readonly_role_name}-group"
  path = "/"
}

resource "aws_iam_group_policy" "readonly_group_policy" {
  name  = "${local.readonly_role_name}-group-policy"
  group = aws_iam_group.readonly_group.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "sts:AssumeRole"
        Effect   = "Allow"
        Resource = aws_iam_role.readonly_role.arn
      }
    ]
  })
}

# Create admin users
resource "aws_iam_user" "admin_users" {
  for_each = var.create_admin_users ? toset(var.admin_users) : []
  name     = each.value
  tags     = var.tags
}

resource "aws_iam_user_group_membership" "admin_users" {
  for_each = var.create_admin_users ? toset(var.admin_users) : []
  user     = aws_iam_user.admin_users[each.value].name
  groups   = [aws_iam_group.admin_group.name]
}

# Create developer users
resource "aws_iam_user" "developer_users" {
  for_each = var.create_developer_users ? toset(var.developer_users) : []
  name     = each.value
  tags     = var.tags
}

resource "aws_iam_user_group_membership" "developer_users" {
  for_each = var.create_developer_users ? toset(var.developer_users) : []
  user     = aws_iam_user.developer_users[each.value].name
  groups   = [aws_iam_group.developer_group.name]
}

# Create readonly users
resource "aws_iam_user" "readonly_users" {
  for_each = var.create_readonly_users ? toset(var.readonly_users) : []
  name     = each.value
  tags     = var.tags
}

resource "aws_iam_user_group_membership" "readonly_users" {
  for_each = var.create_readonly_users ? toset(var.readonly_users) : []
  user     = aws_iam_user.readonly_users[each.value].name
  groups   = [aws_iam_group.readonly_group.name]
}

module "vpc" {
  source       = "git::https://github.com/lroquec/aws-vpc-module.git//?ref=v2.0.1" # Use remote module
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

  custom_ports = {
    22  = "139.47.126.204/32"
    80  = "0.0.0.0/0"
    443 = "0.0.0.0/0"
  }

  tags = local.common_tags
}
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name                   = var.cluster_name
  cluster_version                = var.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_enabled_log_types = [
    "audit",
    "api",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  # Core addons
  # Cluster add-ons configuration
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
      kubernetes_groups = ["system:masters"]
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
    instance_types = var.instance_types

    iam_role_additional_policies = {
      AmazonEBSCSIDriverPolicy     = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    }
  }

  eks_managed_node_groups = {
    main = {
      min_size     = var.min_size
      max_size     = var.max_size
      desired_size = var.desired_size

      instance_types = var.instance_types
      capacity_type  = var.capacity_type

      labels = {
        Environment = var.environment
        NodeGroup   = "main"
      }

      tags = local.common_tags
    }
  }

  tags = local.common_tags
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]
}

resource "null_resource" "update_desired_size" {
  triggers = {
    desired_size = var.desired_size
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<-EOT
      aws eks update-nodegroup-config \
        --cluster-name ${module.eks.cluster_name} \
        --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["main"].node_group_id), 1)} \
        --scaling-config desiredSize=${var.desired_size} \
        --region ${var.aws_region} \
        --profile default
    EOT
  }
}