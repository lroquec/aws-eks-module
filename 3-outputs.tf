output "admin_role_arn" {
  description = "ARN of the admin IAM role"
  value       = aws_iam_role.admin_role.arn
}

output "developer_role_arn" {
  description = "ARN of the developer IAM role"
  value       = aws_iam_role.developer_role.arn
}

output "readonly_role_arn" {
  description = "ARN of the readonly IAM role"
  value       = aws_iam_role.readonly_role.arn
}
