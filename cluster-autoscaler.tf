# Cluster Autoscaler
resource "aws_iam_policy" "cluster_autoscaler" {
  count       = var.enable_cluster_autoscaler ? 1 : 0
  name        = "${var.cluster_name}-cluster-autoscaler"
  path        = "/"
  description = "EKS cluster-autoscaler policy"
  policy      = file("${path.module}/policies/cluster-autoscaler-policy.json")

  tags = local.common_tags
}

locals {
  # Para OIDC, obtener la URL base
  oidc_url = var.enable_cluster_autoscaler ? replace(module.eks.oidc_provider_arn, "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/", "") : ""

  # Map of EKS versions to their compatible Cluster Autoscaler versions
  cluster_autoscaler_versions = {
    "1.29" = "v1.29."
    "1.30" = "v1.30."
    "1.31" = "v1.31."
    "1.32" = "v1.32."
  }

  # Extraer la versión mayor.menor del clúster
  eks_major_minor = var.cluster_version

  # Verificar si la versión está soportada
  is_version_supported = contains(keys(local.cluster_autoscaler_versions), local.eks_major_minor)

  # Obtener la versión compatible del Cluster Autoscaler
  compatible_ca_version = local.is_version_supported ? local.cluster_autoscaler_versions[local.eks_major_minor] : null
}

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${var.cluster_name}-cluster-autoscaler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${local.oidc_url}:aud" : "sts.amazonaws.com",
          "${local.oidc_url}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler-aws"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  count      = var.enable_cluster_autoscaler ? 1 : 0
  policy_arn = aws_iam_policy.cluster_autoscaler[0].arn
  role       = aws_iam_role.cluster_autoscaler[0].name
}

# Version validation
resource "null_resource" "version_validation" {
  count = var.enable_cluster_autoscaler ? 1 : 0

  lifecycle {
    precondition {
      condition     = local.is_version_supported
      error_message = "EKS version ${local.eks_major_minor} is not supported. Supported versions are: ${join(", ", keys(local.cluster_autoscaler_versions))}"
    }
  }

  depends_on = [module.eks]
}

resource "helm_release" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  depends_on = [
    null_resource.version_validation,
    time_sleep.wait_for_cluster,
    time_sleep.wait_for_alb_controller
  ]

  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.34.0" # Especificar una versión estable
  timeout    = 600      # Aumentar timeout para evitar fallos durante instalación

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "image.tag"
    value = "${local.compatible_ca_version}0" # Using .0 as the patch version
  }

  set {
    name  = "rbac.serviceAccount.create"
    value = "true"
  }

  set {
    name  = "rbac.serviceAccount.name"
    value = "cluster-autoscaler-aws"
  }

  set {
    name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.cluster_autoscaler[0].arn
  }

  # Resource configurations
  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "512Mi"
  }

  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "256Mi"
  }

  # Improved probe configuration
  set {
    name  = "livenessProbe.initialDelaySeconds"
    value = "120"
  }

  set {
    name  = "livenessProbe.periodSeconds"
    value = "20"
  }

  set {
    name  = "readinessProbe.initialDelaySeconds"
    value = "30"
  }

  # Configuración importante para el autoscalado adecuado de nodos
  set {
    name  = "extraArgs.scale-down-delay-after-add"
    value = "5m" # Retraso para reducir la escala después de añadir nodos
  }

  set {
    name  = "extraArgs.scale-down-unneeded-time"
    value = "5m" # Tiempo antes de considerar escalar hacia abajo
  }

  set {
    name  = "extraArgs.max-node-provision-time"
    value = "15m" # Máximo tiempo de espera para provisionar nodos
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true" # Equilibrar grupos de nodos similares
  }

  set {
    name  = "extraArgs.expander"
    value = "least-waste" # Estrategia para elegir grupo de nodos cuando se escala
  }

  # Tolerations para permitir que el autoscaler se ejecute incluso en nodos con taints
  set {
    name  = "tolerations[0].key"
    value = "node.kubernetes.io/not-ready"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  set {
    name  = "tolerations[0].effect"
    value = "NoExecute"
  }

  set {
    name  = "tolerations[0].tolerationSeconds"
    value = "300"
  }

  # Tolerations para que funcione incluso durante problemas de nodo
  set {
    name  = "tolerations[1].key"
    value = "node.kubernetes.io/unreachable"
  }

  set {
    name  = "tolerations[1].operator"
    value = "Exists"
  }

  set {
    name  = "tolerations[1].effect"
    value = "NoExecute"
  }

  set {
    name  = "tolerations[1].tolerationSeconds"
    value = "300"
  }

  # Configuración de reintentos para mejorar la fiabilidad
  set {
    name  = "awsRegion"
    value = var.aws_region
  }

  lifecycle {
    create_before_destroy = true
  }
}