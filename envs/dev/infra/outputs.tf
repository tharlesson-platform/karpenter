output "environment" {
  description = "Environment name."
  value       = local.environment
}

output "aws_region" {
  description = "AWS region used by this stack."
  value       = var.aws_region
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "cluster_arn" {
  description = "EKS cluster ARN."
  value       = module.eks.cluster_arn
}

output "cluster_endpoint" {
  description = "EKS API endpoint used by kubectl/helm."
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA data for kubeconfig generation."
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA integrations."
  value       = module.eks.oidc_provider_arn
}

output "oidc_provider_url" {
  description = "OIDC issuer URL for IRSA trust policy construction."
  value       = module.eks.cluster_oidc_issuer_url
}

output "system_node_group_name" {
  description = "Managed node group name reserved for critical components."
  value       = module.eks.system_node_group_name
}

output "node_security_group_id" {
  description = "Shared node security group ID tagged for Karpenter discovery."
  value       = module.eks.node_security_group_id
}

output "karpenter_controller_role_arn" {
  description = "IRSA role ARN for Karpenter controller service account."
  value       = module.iam.controller_role_arn
}

output "karpenter_node_role_arn" {
  description = "Node IAM role ARN used by instances launched by Karpenter."
  value       = module.iam.node_role_arn
}

output "karpenter_node_instance_profile_name" {
  description = "EC2 instance profile name referenced by EC2NodeClass."
  value       = module.iam.node_instance_profile_name
}

output "karpenter_interruption_queue_name" {
  description = "Queue name expected by IAM policy and addons stack."
  value       = local.karpenter_interruption_queue_name
}