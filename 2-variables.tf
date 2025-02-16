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

## Variables for IAM Users
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
