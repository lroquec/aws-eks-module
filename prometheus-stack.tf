# Prometheus Kube Stack
resource "helm_release" "prometheus_stack" {
  count = var.enable_prometheus_stack ? 1 : 0

  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  # No version specified to always use the latest available

  set {
    name  = "grafana.enabled"
    value = "true"
  }

  set {
    name  = "prometheus.enabled"
    value = "true"
  }

  set {
    name  = "alertmanager.enabled"
    value = "true"
  }

  # Resource configuration to avoid excessive usage in test environments
  set {
    name  = "prometheus.prometheusSpec.resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.requests.memory"
    value = "512Mi"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "prometheus.prometheusSpec.resources.limits.memory"
    value = "1Gi"
  }

  # Grafana configuration
  set {
    name  = "grafana.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "grafana.resources.requests.memory"
    value = "256Mi"
  }

  set {
    name  = "grafana.resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "grafana.resources.limits.memory"
    value = "512Mi"
  }

  # AlertManager configuration
  set {
    name  = "alertmanager.resources.requests.cpu"
    value = "50m"
  }

  set {
    name  = "alertmanager.resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "alertmanager.resources.limits.cpu"
    value = "100m"
  }

  set {
    name  = "alertmanager.resources.limits.memory"
    value = "256Mi"
  }

  # Storage configuration for production environments
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
  }
  
  # Add deletion policy to ensure PVCs are removed with terraform destroy
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.persistentVolumeReclaimPolicy"
    value = "Delete"
  }
  
  set {
    name  = "prometheus.prometheusSpec.retention"
    value = var.prometheus_retention
  }
  
  set {
    name  = "grafana.persistence.enabled"
    value = "true"
  }
  
  set {
    name  = "grafana.persistence.size"
    value = var.grafana_storage_size
  }
  
  # Add deletion annotation for Grafana PVC
  set {
    name  = "grafana.persistence.annotations.helm\\.sh/resource-policy"
    value = "delete"
  }
  
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alertmanager_storage_size
  }
  
  # Add deletion policy for AlertManager PVC
  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.persistentVolumeReclaimPolicy"
    value = "Delete"
  }

  # ServiceMonitor configuration
  set {
    name  = "prometheusOperator.serviceMonitor.enabled"
    value = "true"
  }
  
  # Security configuration for production
  set {
    name  = "prometheus.prometheusSpec.securityContext.fsGroup"
    value = "65534"
  }
  
  set {
    name  = "prometheus.prometheusSpec.securityContext.runAsNonRoot"
    value = "true"
  }
  
  set {
    name  = "prometheus.prometheusSpec.securityContext.runAsUser"
    value = "65534"
  }
  
  # High availability configuration for production
  set {
    name  = "prometheusOperator.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }
  
  set {
    name  = "prometheus.prometheusSpec.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }
  
  set {
    name  = "alertmanager.alertmanagerSpec.replicas"
    value = var.environment == "prod" ? "2" : "1"
  }
  
  # Metric retention configuration based on size and time
  set {
    name  = "prometheus.prometheusSpec.retentionSize"
    value = var.environment == "prod" ? "85GB" : "30GB"
  }
  
  # Grafana configuration 
  set {
    name  = "grafana.adminPassword"
    value = var.grafana_admin_password
  }
  
  # Ingress configuration if needed
  dynamic "set" {
    for_each = var.enable_prometheus_ingress ? [1] : []
    content {
      name  = "grafana.ingress.enabled"
      value = "true"
    }
  }
  
  dynamic "set" {
    for_each = var.enable_prometheus_ingress ? [1] : []
    content {
      name  = "grafana.ingress.ingressClassName" 
      value = "alb"
    }
  }
  
  # Labels for all resources
  set {
    name  = "commonLabels.environment"
    value = var.environment
  }
  
  set {
    name  = "commonLabels.managed-by"
    value = "terraform"
  }

  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp2-immediate"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "gp2-immediate"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "gp2-immediate"
  }

  depends_on = [module.eks, time_sleep.wait_for_cluster, kubectl_manifest.gp2_immediate]
}

# Custom Prometheus Alert Rules (applied only if prometheus-stack is enabled)
resource "kubectl_manifest" "prometheus_alert_rules" {
  count     = var.enable_prometheus_stack ? 1 : 0
  yaml_body = file("${path.module}/policies/prometheus-alerts.yaml")
  
  depends_on = [
    helm_release.prometheus_stack
  ]
}
