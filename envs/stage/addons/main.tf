locals {
  environment = "stage"

  common_tags = merge(
    var.default_tags,
    {
      Environment   = local.environment
      TerraformRoot = "envs/stage/addons"
      Component     = "karpenter"
    }
  )

  effective_helm_values_path = coalesce(
    var.helm_values_path,
    "${path.root}/../../../helm-values/karpenter-values-stage.yaml"
  )
}

data "terraform_remote_state" "infra" {
  backend = "s3"

  config = merge(
    {
      bucket = var.infra_state_bucket
      key    = var.infra_state_key
      region = var.infra_state_region
    },
    var.infra_state_lock_table == null ? {} : { dynamodb_table = var.infra_state_lock_table }
  )
}

module "karpenter" {
  source = "../../../modules/karpenter"

  environment                       = local.environment
  cluster_name                      = data.terraform_remote_state.infra.outputs.cluster_name
  cluster_endpoint                  = data.terraform_remote_state.infra.outputs.cluster_endpoint
  karpenter_namespace               = var.karpenter_namespace
  karpenter_version                 = var.karpenter_version
  controller_role_arn               = data.terraform_remote_state.infra.outputs.karpenter_controller_role_arn
  system_node_group_name            = data.terraform_remote_state.infra.outputs.system_node_group_name
  helm_values_path                  = local.effective_helm_values_path
  controller_replicas               = var.controller_replicas
  controller_log_level              = var.controller_log_level
  enable_spot_interruption_handling = var.enable_spot_interruption_handling
  interruption_queue_name           = data.terraform_remote_state.infra.outputs.karpenter_interruption_queue_name
  tags                              = local.common_tags
}
