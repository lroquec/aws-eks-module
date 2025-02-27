alertmanager:
  enabled: true
  alertmanagerSpec:
    replicas: 1
    resources:
      requests:
        cpu: "50m"
        memory: "128Mi"
      limits:
        cpu: "100m"
        memory: "256Mi"
    storage:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: "${alertmanager_storage_size}"
          storageClassName: "gp2"
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: "topology.kubernetes.io/zone"
              labelSelector:
                matchExpressions:
                  - key: "app"
                    operator: "In"
                    values:
                      - "alertmanager"
grafana:
  enabled: true
  adminPassword: "${grafana_admin_password}"
  resources:
    requests:
      cpu: "50m"
      memory: "256Mi"
    limits:
      cpu: "100m"
      memory: "512Mi"
  persistence:
    enabled: true
    size: "${grafana_storage_size}"
    storageClassName: "gp2"
  ingress:
    enabled: false
prometheus:
  enabled: true
  prometheusSpec:
    replicas: 1
    resources:
      requests:
        cpu: "100m"
        memory: "512Mi"
      limits:
        cpu: "200m"
        memory: "1Gi"
    storageSpec:
      volumeClaimTemplate:
        spec:
          resources:
            requests:
              storage: "${prometheus_storage_size}"
          storageClassName: "gp2"
    retention: "${prometheus_retention}"
    retentionSize: "20GB"
    securityContext:
      fsGroup: 65534
      runAsNonRoot: true
      runAsUser: 65534
    affinity:
      podAntiAffinity:
        preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              topologyKey: "topology.kubernetes.io/zone"
              labelSelector:
                matchExpressions:
                  - key: "app"
                    operator: "In"
                    values:
                      - "prometheus"
    tolerations:
      - key: "node.kubernetes.io/not-ready"
        operator: "Exists"
        effect: "NoExecute"
        tolerationSeconds: 300
prometheusOperator:
  replicas: 1
  serviceMonitor:
    enabled: true
commonLabels:
  environment: "prod"
  managed-by: "terraform"
