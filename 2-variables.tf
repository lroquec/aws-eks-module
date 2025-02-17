variable "name_prefix" {
  description = "Prefix for all resources"
  type        = string
  default     = "eks"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "Region in which AWS Resources to be created"
  type        = string
  default     = "us-east-1"
}

#  Variables for IAM Users
variable "create_admin_users" {
  description = "Whether to create admin IAM users"
  type        = bool
  default     = false
}

variable "create_developer_users" {
  description = "Whether to create developer IAM users"
  type        = bool
  default     = false
}

variable "create_readonly_users" {
  description = "Whether to create readonly IAM users"
  type        = bool
  default     = false
}

variable "admin_users" {
  description = "List of admin users to create"
  type        = list(string)
  default     = []
}

variable "developer_users" {
  description = "List of developer users to create"
  type        = list(string)
  default     = []
}

variable "readonly_users" {
  description = "List of readonly users to create"
  type        = list(string)
  default     = []
}

#  Variables for EKS
variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "test-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.31"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# variable "instance_types" {
#   description = "List of EC2 instance types for the node group"
#   type        = list(string)
#   default     = ["t3.medium"]
# }

# variable "min_size" {
#   description = "Minimum size of the node group"
#   type        = number
#   default     = 1
# }

# variable "max_size" {
#   description = "Maximum size of the node group"
#   type        = number
#   default     = 2
# }

# variable "desired_size" {
#   description = "Desired size of the node group"
#   type        = number
#   default     = 1
# }

# variable "capacity_type" {
#   description = "Type of capacity associated with the EKS Node Group. Valid values: ON_DEMAND, SPOT"
#   type        = string
#   default     = "ON_DEMAND"

#   validation {
#     condition     = contains(["ON_DEMAND", "SPOT"], var.capacity_type)
#     error_message = "Capacity type must be either ON_DEMAND or SPOT"
#   }
# }

variable "accountable" {
  description = "Accountable team for the EKS cluster"
  type        = string
  default     = "devops"
}

variable "git_repo" {
  description = "Git repository to clone"
  type        = string
  default     = "https://github.com/company/ecommerce-platform"
}

variable "enable_ebs_csi_driver" {
  description = "Enable EBS CSI driver add-on"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_observability" {
  description = "Enable CloudWatch observability add-on"
  type        = bool
  default     = false
}

variable "enable_efs_csi_driver" {
  description = "Enable EFS CSI driver add-on"
  type        = bool
  default     = false
}

variable "enable_metrics_server" {
  description = "Enable metrics server"
  type        = bool
  default     = true
}

variable "enable_load_balancer_controller" {
  description = "Enable AWS Load Balancer Controller"
  type        = bool
  default     = true
}

variable "enable_external_dns" {
  description = "Enable external DNS"
  type        = bool
  default     = true
}

variable "enable_karpenter" {
  description = "Enable Karpenter node provisioner"
  type        = bool
  default     = false
}

variable "karpenter_version" {
  description = "Version of Karpenter to install"
  type        = string
  default     = "v0.34.0"
}