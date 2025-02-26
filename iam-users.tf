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
