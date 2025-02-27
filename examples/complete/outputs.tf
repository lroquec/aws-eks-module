output "cluster_endpoint" {
  description = "Endpoint for EKS cluster"
  value       = module.eks.cluster_endpoint
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.eks.vpc_id
}

output "kubeconfig" {
  description = "Kubeconfig for EKS cluster"
  value       = module.eks.kubeconfig
}