locals {
  cluster_tags = merge(
    var.tags,
    {
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.37.2"

  cluster_name                             = var.cluster_name
  cluster_version                          = var.kubernetes_version
  authentication_mode                      = var.authentication_mode
  enable_cluster_creator_admin_permissions = var.enable_cluster_creator_admin_permissions

  cluster_endpoint_private_access = var.cluster_endpoint_private_access
  cluster_endpoint_public_access  = var.cluster_endpoint_public_access
  cluster_enabled_log_types       = var.cluster_enabled_log_types

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.cluster_log_retention_days

  vpc_id                                = var.vpc_id
  subnet_ids                            = var.private_subnet_ids
  control_plane_subnet_ids              = var.private_subnet_ids
  cluster_additional_security_group_ids = var.cluster_security_group_additional_ids

  enable_irsa = true

  cluster_addons = {
    coredns = {
      addon_version               = var.addon_versions.coredns
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    kube-proxy = {
      addon_version               = var.addon_versions.kube_proxy
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    vpc-cni = {
      addon_version               = var.addon_versions.vpc_cni
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
    eks-pod-identity-agent = {
      addon_version               = var.addon_versions.pod_identity_agent
      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"
    }
  }

  eks_managed_node_groups = {
    (var.system_node_group.name) = {
      min_size     = var.system_node_group.min_size
      max_size     = var.system_node_group.max_size
      desired_size = var.system_node_group.desired_size

      ami_type       = var.system_node_group.ami_type
      capacity_type  = var.system_node_group.capacity_type
      disk_size      = var.system_node_group.disk_size
      instance_types = var.system_node_group.instance_types

      labels = merge(
        var.system_node_group.labels,
        {
          "workload-tier"           = "core"
          "karpenter.sh/controller" = "true"
        }
      )

      update_config = {
        max_unavailable = var.system_node_group.max_unavailable
      }

      metadata_options = {
        http_endpoint               = "enabled"
        http_tokens                 = "required"
        http_put_response_hop_limit = 2
      }

      tags = merge(
        var.tags,
        {
          "Name" = "${var.cluster_name}-${var.system_node_group.name}"
        }
      )
    }
  }

  node_security_group_tags = merge(
    local.cluster_tags,
    {
      "karpenter.sh/discovery" = var.cluster_name
    }
  )

  cluster_tags = local.cluster_tags
  tags         = var.tags
}