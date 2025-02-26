resource "helm_release" "prometheus_stack" {
  count            = var.enable_prometheus_stack ? 1 : 0
  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  force_update = true

  values = [
    file("${path.module}/values/prometheus_stack_values.yaml")
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
