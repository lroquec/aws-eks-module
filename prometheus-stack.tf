# Prometheus Kube Stack
resource "helm_release" "prometheus_stack" {
  count = var.enable_prometheus_stack ? 1 : 0

  name             = "prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  # Configuración básica
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

  # Resource configuration to avoid excessive usage
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

  # Configuración Grafana
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

  # Configuración AlertManager
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

  # Usar la StorageClass con WaitForFirstConsumer
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.storageClassName"
    value = "gp2"
  }

  set {
    name  = "grafana.persistence.storageClassName"
    value = "gp2"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.storageClassName"
    value = "gp2"
  }

  # Configuración de anti-afinidad para distribuir los pods entre nodos
  set {
    name  = "prometheus.prometheusSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey"
    value = "topology.kubernetes.io/zone"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].key"
    value = "app"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "prometheus.prometheusSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].values[0]"
    value = "prometheus"
  }

  # Configuración similar para AlertManager
  set {
    name  = "alertmanager.alertmanagerSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].weight"
    value = "100"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.topologyKey"
    value = "topology.kubernetes.io/zone"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].key"
    value = "app"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].operator"
    value = "In"
  }

  set {
    name  = "alertmanager.alertmanagerSpec.affinity.podAntiAffinity.preferredDuringSchedulingIgnoredDuringExecution[0].podAffinityTerm.labelSelector.matchExpressions[0].values[0]"
    value = "alertmanager"
  }

  # Configurar tolerancias para permitir que los pods se programen en más nodos
  set {
    name  = "prometheus.prometheusSpec.tolerations[0].key"
    value = "node.kubernetes.io/not-ready"
  }

  set {
    name  = "prometheus.prometheusSpec.tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "prometheus.prometheusSpec.tolerations[0].effect"
    value = "NoExecute"
  }

  set {
    name  = "prometheus.prometheusSpec.tolerations[0].tolerationSeconds"
    value = "300"
  }

  # Storage configuration
  set {
    name  = "prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.prometheus_storage_size
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

  set {
    name  = "alertmanager.alertmanagerSpec.storage.volumeClaimTemplate.spec.resources.requests.storage"
    value = var.alertmanager_storage_size
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

  # High availability configuration 
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

  # Metric retention configuration
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

  # Labels
  set {
    name  = "commonLabels.environment"
    value = var.environment
  }

  set {
    name  = "commonLabels.managed-by"
    value = "terraform"
  }

  depends_on = [
    module.eks,
    time_sleep.wait_for_cluster
  ]

  # Agregar lógica para recrear recursos si es necesario
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
