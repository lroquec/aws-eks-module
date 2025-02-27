variable "grafana_admin_password" {
  description = "Admin password for Grafana"
  type        = string
  default     = "prom-operator"
}

variable "grafana_ingress_host" {
  description = "Grafana Ingress Host"
  type        = string
  default     = "grafana.example.com"
}
