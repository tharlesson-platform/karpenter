output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS cluster API server endpoint."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64 cluster CA bundle used by Kubernetes and Helm providers."
  value       = module.eks.cluster_certificate_authority_data
}

output "cluster_oidc_issuer_url" {
  description = "Cluster OIDC issuer URL used by IRSA roles."
  value       = module.eks.cluster_oidc_issuer_url
}

output "oidc_provider" {
  description = "OIDC provider identifier."
  value       = module.eks.oidc_provider
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN used in IRSA trust policies."
  value       = module.eks.oidc_provider_arn
}

output "cluster_primary_security_group_id" {
  description = "Primary security group managed by EKS for control plane/node communication."
  value       = module.eks.cluster_primary_security_group_id
}

output "node_security_group_id" {
  description = "Shared node security group for managed node groups."
  value       = module.eks.node_security_group_id
}

output "system_node_group_name" {
  description = "Managed node group that keeps core components running."
  value       = var.system_node_group.name
}

output "system_node_group_iam_role_arn" {
  description = "IAM role ARN used by the fixed managed node group."
  value       = module.eks.eks_managed_node_groups[var.system_node_group.name].iam_role_arn
}