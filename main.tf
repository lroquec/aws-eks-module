# Get current AWS account information
data "aws_caller_identity" "current" {}

# Define local variables
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

# Wait for EKS cluster to be ready before proceeding with add-ons
resource "null_resource" "wait_for_cluster" {
  depends_on = [module.eks]
}

resource "time_sleep" "wait_for_cluster" {
  depends_on      = [module.eks]
  create_duration = "30s"
}
