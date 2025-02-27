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
  default     = "1.32"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

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
  default     = "1.2.1"
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "enable_prometheus_stack" {
  description = "Enable Prometheus Kube Stack (Prometheus, Grafana, AlertManager)"
  type        = bool
  default     = false
}

variable "prometheus_storage_size" {
  description = "Storage size for Prometheus server"
  type        = string
  default     = "50Gi"
}

variable "prometheus_retention" {
  description = "Data retention period for Prometheus"
  type        = string
  default     = "15d"
}

variable "grafana_storage_size" {
  description = "Storage size for Grafana"
  type        = string
  default     = "10Gi"
}

variable "alertmanager_storage_size" {
  description = "Storage size for AlertManager"
  type        = string
  default     = "5Gi"
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  sensitive   = true
  default     = "prom-operator"
}

variable "enable_grafana_ingress" {
  description = "Enable Ingress for Grafana dashboard"
  type        = bool
  default     = false
}

variable "grafana_ingress_host" {
  description = "The host for the Grafana ingress"
  type        = string
  default     = "grafana.example.com"
}

# Validation rules
locals {
  # Ensure that both Karpenter and Cluster Autoscaler are not enabled simultaneously
  error_both_scalers = tobool(var.enable_karpenter && var.enable_cluster_autoscaler ?
  file("ERROR: You cannot enable both Karpenter and Cluster Autoscaler simultaneously as they would conflict with each other.") : true)

  # Ensure that both Prometheus Stack and CloudWatch Observability are not enabled simultaneously
  error_both_monitoring = tobool(var.enable_prometheus_stack && var.enable_cloudwatch_observability ?
  file("ERROR: You cannot enable both Prometheus Stack and CloudWatch Observability simultaneously as they would conflict with each other.") : true)

  # Validate storage sizes for Prometheus Stack
  error_prometheus_storage = tobool(var.enable_prometheus_stack &&
    (tonumber(regex("^(\\d+)Gi$", var.prometheus_storage_size)[0]) < 10 ||
      tonumber(regex("^(\\d+)Gi$", var.grafana_storage_size)[0]) < 2 ||
    tonumber(regex("^(\\d+)Gi$", var.alertmanager_storage_size)[0]) < 1) ?
  file("ERROR: Storage sizes for Prometheus components are too small for reliable operation. Minimum recommended: prometheus_storage_size=10Gi, grafana_storage_size=2Gi, alertmanager_storage_size=1Gi") : true)
}
