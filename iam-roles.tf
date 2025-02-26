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
