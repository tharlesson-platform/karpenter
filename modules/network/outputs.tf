output "tagged_private_subnet_ids" {
  description = "Private subnets tagged for Karpenter discovery."
  value       = keys(aws_ec2_tag.private_subnet_discovery)
}

output "tagged_security_group_ids" {
  description = "Security groups tagged for Karpenter discovery."
  value       = keys(aws_ec2_tag.security_group_discovery)
}