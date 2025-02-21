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

# Admin Role Policy - More restrictive permissions
resource "aws_iam_role_policy" "admin_policy" {
  name = "${local.admin_role_name}-policy"
  role = aws_iam_role.admin_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:UpdateClusterVersion",
          "eks:UpdateClusterConfig"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      },
      {
        Action = [
          "iam:ListRoles"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
      },
      {
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/eks/${var.cluster_name}/*"
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

# Developer Role Policy - More restrictive permissions
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
          "eks:AccessKubernetesApi"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      },
      {
        Action = [
          "iam:ListRoles"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
      },
      {
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/eks/${var.cluster_name}/*"
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

# Readonly Role Policy - More restrictive permissions
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
          "eks:AccessKubernetesApi"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      },
      {
        Action = [
          "iam:ListRoles"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"
      },
      {
        Action = [
          "ssm:GetParameter"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter/eks/${var.cluster_name}/*"
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
      max_size     = 1
      desired_size = 1

      instance_types = ["t3.medium"]
      capacity_type  = "ON_DEMAND"

      labels = {
        Environment = var.environment
        NodeGroup   = "initial"
        Purpose     = "bootstrap"
      }

      tags = local.common_tags
    }
  }

  tags = local.common_tags
}

resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]
}

# resource "null_resource" "update_desired_size" {
#   triggers = {
#     desired_size = var.desired_size
#   }

#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]

#     command = <<-EOT
#       aws eks update-nodegroup-config \
#         --cluster-name ${module.eks.cluster_name} \
#         --nodegroup-name ${element(split(":", module.eks.eks_managed_node_groups["main"].node_group_id), 1)} \
#         --scaling-config desiredSize=${var.desired_size} \
#         --region ${var.aws_region} \
#         --profile default
#     EOT
#   }
# }

# Metrics Server
resource "helm_release" "metrics_server" {
  count = var.enable_metrics_server ? 1 : 0

  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
}

# AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  name        = "${var.cluster_name}-aws-load-balancer-controller"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/aws-load-balancer-controller-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  name = "${var.cluster_name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
  role       = aws_iam_role.aws_load_balancer_controller[0].name
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller[0].arn
  }
}

# External DNS
resource "aws_iam_policy" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name        = "${var.cluster_name}-external-dns"
  description = "Policy for External DNS"
  policy      = file("${path.module}/policies/external-dns-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name = "${var.cluster_name}-external-dns"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:external-dns"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  policy_arn = aws_iam_policy.external_dns[0].arn
  role       = aws_iam_role.external_dns[0].name
}

resource "helm_release" "external_dns" {
  count = var.enable_external_dns ? 1 : 0

  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.external_dns[0].arn
  }

  set {
    name  = "provider"
    value = "aws"
  }
}

# Karpenter IAM Role
resource "aws_iam_role" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:karpenter:karpenter"
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy" "karpenter_controller" {
  count = var.enable_karpenter ? 1 : 0
  name  = "karpenter-policy"
  role  = aws_iam_role.karpenter_controller[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:RunInstances",
          "ec2:CreateTags",
          "iam:PassRole",
          "ec2:TerminateInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts",
          "iam:CreateInstanceProfile",
          "iam:DeleteInstanceProfile",
          "iam:GetInstanceProfile",
          "iam:TagInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "arn:aws:eks:${var.aws_region}:${data.aws_caller_identity.current.account_id}:cluster/${var.cluster_name}"
      }
    ]
  })

}

# Create Karpenter node IAM role
resource "aws_iam_role" "karpenter_node" {
  count = var.enable_karpenter ? 1 : 0
  name  = "${var.cluster_name}-karpenter-node"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "karpenter_node_policies" {
  for_each = var.enable_karpenter ? toset([
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]) : []

  policy_arn = each.value
  role       = aws_iam_role.karpenter_node[0].name
}

resource "time_sleep" "wait_for_cluster" {
  depends_on      = [module.eks]
  create_duration = "30s"
}

resource "helm_release" "karpenter" {
  count = var.enable_karpenter ? 1 : 0

  namespace        = "karpenter"
  create_namespace = true

  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = var.karpenter_version

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_controller[0].arn
  }
  set {
    name  = "crds.install"
    value = "true"
  }

  depends_on = [time_sleep.wait_for_cluster]
}

# resource "null_resource" "install_karpenter_crds" {
#   provisioner "local-exec" {
#     command = <<EOT
#       kubectl apply -f https://raw.githubusercontent.com/aws/karpenter/main/pkg/apis/crds/karpenter.sh_nodeclaims.yaml
#       kubectl apply -f https://raw.githubusercontent.com/aws/karpenter/main/pkg/apis/crds/karpenter.sh_nodepools.yaml
#       kubectl apply -f https://raw.githubusercontent.com/aws/karpenter/main/pkg/apis/crds/karpenter.k8s.aws_ec2nodeclasses.yaml
#     EOT
#   }

#   depends_on = [helm_release.karpenter]
# }

# 3. Wait till CRDs
resource "time_sleep" "wait_for_crds" {
  count           = var.enable_karpenter ? 1 : 0
  depends_on      = [helm_release.karpenter]
  create_duration = "30s"
}

resource "kubectl_manifest" "karpenter_provisioner" {
  count      = var.enable_karpenter ? 1 : 0
  depends_on = [time_sleep.wait_for_crds]
  yaml_body  = <<-YAML
apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: default
spec:
  template:
    spec:
      requirements:
        - key: kubernetes.io/arch
          operator: In
          values: ["amd64"]
        - key: kubernetes.io/os
          operator: In
          values: ["linux"]
        - key: karpenter.sh/capacity-type
          operator: In
          values: ["spot"]
        - key: node.kubernetes.io/instance-type
          operator: In
          values: ["t3.small", "t3.medium"]
      nodeClassRef:
        name: default
  limits:
    cpu: 50
    memory: 50Gi
  disruption:
    consolidationPolicy: WhenEmpty
    consolidateAfter: 30s
YAML
}

resource "kubectl_manifest" "karpenter_node_template" {
  count      = var.enable_karpenter ? 1 : 0
  depends_on = [helm_release.karpenter]
  yaml_body  = <<-YAML
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: default
spec:
  amiFamily: AL2023
  role: "${aws_iam_role.karpenter_node[0].name}"
  subnetSelectorTerms:
    - tags:
        kubernetes.io/role: private
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/${module.eks.cluster_name}: owned
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 20Gi
        volumeType: gp3
  tags:
    Environment: ${var.environment}
    ManagedBy: karpenter
    Purpose: testing
YAML
}
