# AWS Load Balancer Controller
resource "aws_iam_policy" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  name        = "${var.cluster_name}-aws-load-balancer-controller"
  description = "Policy for AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/aws-load-balancer-controller-policy.json")

  tags = local.common_tags
}

resource "aws_iam_role" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  name = "${var.cluster_name}-aws-load-balancer-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRoleWithWebIdentity"
      Effect = "Allow"
      Principal = {
        Federated = module.eks.oidc_provider_arn
      }
      Condition = {
        StringEquals = {
          "${replace(module.eks.oidc_provider_arn, "/^(.*provider/)/", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })

  tags = local.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  policy_arn = aws_iam_policy.aws_load_balancer_controller[0].arn
  role       = aws_iam_role.aws_load_balancer_controller[0].name
}

# Verificamos que el namespace kube-system está disponible
resource "null_resource" "check_kube_system" {
  count = var.enable_load_balancer_controller ? 1 : 0

  depends_on = [module.eks, time_sleep.wait_for_cluster]

  provisioner "local-exec" {
    command = "kubectl get namespace kube-system"
  }
}

resource "helm_release" "aws_load_balancer_controller" {
  count = var.enable_load_balancer_controller ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.6.2" # Especificar una versión estable

  set {
    name  = "clusterName"
    value = var.cluster_name
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.aws_load_balancer_controller[0].arn
  }

  # Configuración para alta disponibilidad
  set {
    name  = "replicaCount"
    value = "2"
  }

  # Configuración de recursos para evitar problemas de límites
  set {
    name  = "resources.requests.cpu"
    value = "100m"
  }

  set {
    name  = "resources.requests.memory"
    value = "128Mi"
  }

  set {
    name  = "resources.limits.cpu"
    value = "200m"
  }

  set {
    name  = "resources.limits.memory"
    value = "256Mi"
  }

  # Aumentar el timeout para permitir que los webhooks se registren correctamente
  timeout = 600

  depends_on = [
    module.eks,
    time_sleep.wait_for_cluster,
    null_resource.check_kube_system,
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]

  lifecycle {
    create_before_destroy = true
  }
}

# Esperar a que el controlador esté completamente disponible
resource "time_sleep" "wait_for_alb_controller" {
  count           = var.enable_load_balancer_controller ? 1 : 0
  depends_on      = [helm_release.aws_load_balancer_controller]
  create_duration = "90s"
}
