data "aws_caller_identity" "current" {}

locals {
  admin_role_name     = "${var.name_prefix}-admin"
  developer_role_name = "${var.name_prefix}-developer"
  readonly_role_name  = "${var.name_prefix}-readonly"
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

  tags = var.tags
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

