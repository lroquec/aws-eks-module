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

  provisioner "local-exec" {
    when    = destroy
    command = "kubectl delete pvc -n monitoring -l app.kubernetes.io/instance=prometheus-stack --ignore-not-found=true || true"
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

resource "kubernetes_ingress" "grafana_ingress" {
  count = var.enable_grafana_ingress ? 1 : 0
  metadata {
    name      = "grafana-ingress"
    namespace = "monitoring"
    annotations = {
      "kubernetes.io/ingress.class"               = "alb"
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip"
      "alb.ingress.kubernetes.io/listen-ports"    = jsonencode([{ "HTTPS" : 443 }, { "HTTP" : 80 }])
      "alb.ingress.kubernetes.io/certificate-arn" = "arn:aws:acm:us-east-1:010526263844:certificate/99aa29a8-9b69-461e-9802-1dc8acd5a004"
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "external-dns.alpha.kubernetes.io/hostname" = var.grafana_ingress_host
    }
  }

  spec {
    rule {
      host = var.grafana_ingress_host

      http {
        path {
          path = "/"
          backend {
            service_name = "prometheus-stack-grafana"
            service_port = 80
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.prometheus_stack
  ]
}
