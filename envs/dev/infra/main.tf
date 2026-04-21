locals {
  environment = "dev"

  karpenter_interruption_queue_name = coalesce(
    var.karpenter_interruption_queue_name,
    "${var.cluster_name}-karpenter-interruptions"
  )

  common_tags = merge(
    var.default_tags,
    {
      Environment   = local.environment
      TerraformRoot = "envs/dev/infra"
      Component     = "eks-karpenter"
    }
  )
}

module "eks" {
  source = "../../../modules/eks"

  cluster_name                             = var.cluster_name
  kubernetes_version                       = var.kubernetes_version
  vpc_id                                   = var.vpc_id
  private_subnet_ids                       = var.private_subnet_ids
  cluster_endpoint_private_access          = var.cluster_endpoint_private_access
  cluster_endpoint_public_access           = var.cluster_endpoint_public_access
  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions
  addon_versions                           = var.addon_versions
  system_node_group                        = var.system_node_group
  tags                                     = local.common_tags
}

module "network" {
  source = "../../../modules/network"

  cluster_name                      = var.cluster_name
  private_subnet_ids                = var.private_subnet_ids
  discovery_security_group_ids      = [module.eks.node_security_group_id, module.eks.cluster_primary_security_group_id]
  tag_subnets_for_karpenter         = true
  tag_security_groups_for_karpenter = true
}

module "iam" {
  source = "../../../modules/iam"

  aws_region                     = var.aws_region
  cluster_name                   = var.cluster_name
  cluster_arn                    = module.eks.cluster_arn
  oidc_provider_arn              = module.eks.oidc_provider_arn
  oidc_provider_url              = module.eks.cluster_oidc_issuer_url
  karpenter_namespace            = var.karpenter_namespace
  karpenter_service_account_name = var.karpenter_service_account_name
  interruption_queue_name        = local.karpenter_interruption_queue_name
  permissions_boundary_arn       = var.permissions_boundary_arn
  create_node_access_entry       = true
  tags                           = local.common_tags
}