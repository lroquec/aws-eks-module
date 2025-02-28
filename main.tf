# Get current AWS account information
data "aws_caller_identity" "current" {}

# Define local variables
locals {
  admin_role_name     = "${var.name_prefix}-admin"
  developer_role_name = "${var.name_prefix}-developer"
  readonly_role_name  = "${var.name_prefix}-readonly"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  )
}

resource "time_sleep" "wait_for_cluster" {
  depends_on      = [module.eks]
  create_duration = "90s"

  triggers = {
    cluster_endpoint = module.eks.cluster_endpoint
  }
}

resource "null_resource" "check_cluster_readiness" {
  depends_on = [time_sleep.wait_for_cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      echo "Verificando disponibilidad del cluster EKS..."
      
      # Configurar kubectl
      aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.aws_region}
      
      # Esperar hasta que los nodos estén Ready
      echo "Esperando a que los nodos estén disponibles..."
      kubectl wait --for=condition=Ready nodes --all --timeout=300s
      
      # Verificar que kube-system pods están en ejecución
      echo "Verificando pods del sistema..."
      kubectl wait --for=condition=Ready pods --all -n kube-system --timeout=300s
      
      echo "Cluster EKS disponible y listo para usar"
    EOT
  }
}
