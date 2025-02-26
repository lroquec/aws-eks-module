resource "helm_release" "prometheus_stack" {
  count            = var.enable_prometheus_stack ? 1 : 0
  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  force_update = true

  values = [
    templatefile("${path.module}/values/prometheus_stack_values.yaml.tpl", {
      grafana_admin_password    = var.grafana_admin_password
      enable_prometheus_ingress = var.enable_prometheus_ingress
      prometheus_storage_size   = var.prometheus_storage_size
      prometheus_retention      = var.prometheus_retention
      grafana_storage_size      = var.grafana_storage_size
      alertmanager_storage_size = var.alertmanager_storage_size
    })
  ]

  depends_on = [
    module.eks,
    time_sleep.wait_for_cluster
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Custom Prometheus Alert Rules (applied only if prometheus-stack is enabled)
resource "kubectl_manifest" "prometheus_alert_rules" {
  count     = var.enable_prometheus_stack ? 1 : 0
  yaml_body = file("${path.module}/policies/prometheus-alerts.yaml")

  depends_on = [
    helm_release.prometheus_stack
  ]
}
