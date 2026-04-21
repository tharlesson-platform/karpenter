output "controller_role_arn" {
  description = "IAM role ARN for Karpenter controller service account (IRSA)."
  value       = aws_iam_role.karpenter_controller.arn
}

output "controller_policy_arn" {
  description = "IAM policy ARN attached to Karpenter controller role."
  value       = aws_iam_policy.karpenter_controller.arn
}

output "node_role_arn" {
  description = "IAM role ARN used by EC2 instances launched by Karpenter."
  value       = aws_iam_role.karpenter_node.arn
}

output "node_role_name" {
  description = "Karpenter node IAM role name."
  value       = aws_iam_role.karpenter_node.name
}

output "node_instance_profile_name" {
  description = "EC2 instance profile name used by EC2NodeClass."
  value       = aws_iam_instance_profile.karpenter_node.name
}

output "node_instance_profile_arn" {
  description = "EC2 instance profile ARN used by EC2NodeClass."
  value       = aws_iam_instance_profile.karpenter_node.arn
}

output "node_access_entry_id" {
  description = "EKS access entry ID for Karpenter node role."
  value       = try(aws_eks_access_entry.karpenter_node[0].id, null)
}