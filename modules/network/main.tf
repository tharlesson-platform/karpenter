locals {
  subnet_tag_payload = var.tag_subnets_for_karpenter ? {
    for subnet_id in var.private_subnet_ids :
    subnet_id => subnet_id
  } : {}

  security_group_tag_payload = var.tag_security_groups_for_karpenter ? {
    for sg_id in var.discovery_security_group_ids :
    sg_id => sg_id
  } : {}
}

resource "aws_ec2_tag" "private_subnet_discovery" {
  for_each = local.subnet_tag_payload

  resource_id = each.value
  key         = var.karpenter_discovery_tag_key
  value       = var.cluster_name
}

resource "aws_ec2_tag" "security_group_discovery" {
  for_each = local.security_group_tag_payload

  resource_id = each.value
  key         = var.karpenter_discovery_tag_key
  value       = var.cluster_name
}