variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name for this environment."
  type        = string
}

variable "kubernetes_version" {
  description = "Pinned Kubernetes version for EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "Existing VPC ID used by the cluster."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnets where EKS and Karpenter nodes will run."
  type        = list(string)
}

variable "cluster_endpoint_private_access" {
  description = "Enable private endpoint for EKS API."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Enable public endpoint for EKS API."
  type        = bool
  default     = false
}

variable "authentication_mode" {
  description = "EKS authentication mode. API mode uses access entries and avoids aws-auth dependency."
  type        = string
  default     = "API"
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Temporarily grants admin to the identity creating the cluster."
  type        = bool
  default     = true
}

variable "addon_versions" {
  description = "Pinned addon versions for CoreDNS, kube-proxy, VPC CNI and pod identity agent."
  type = object({
    coredns            = string
    kube_proxy         = string
    vpc_cni            = string
    pod_identity_agent = string
  })
}

variable "system_node_group" {
  description = "Managed node group that hosts core platform components."
  type = object({
    name            = string
    desired_size    = number
    min_size        = number
    max_size        = number
    instance_types  = list(string)
    ami_type        = string
    disk_size       = number
    capacity_type   = string
    max_unavailable = number
    labels          = map(string)
  })
}

variable "karpenter_namespace" {
  description = "Namespace for Karpenter controller service account."
  type        = string
  default     = "karpenter"
}

variable "karpenter_service_account_name" {
  description = "Service account name for Karpenter controller."
  type        = string
  default     = "karpenter"
}

variable "karpenter_interruption_queue_name" {
  description = "Optional queue name override for interruption handling permissions."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary for enterprise controls."
  type        = string
  default     = null
}

variable "default_tags" {
  description = "Mandatory standard tags for governance and cost allocation."
  type        = map(string)

  validation {
    condition = alltrue([
      for required_key in ["Project", "ManagedBy", "Owner", "CostCenter"] :
      contains(keys(var.default_tags), required_key)
    ])
    error_message = "default_tags must include Project, ManagedBy, Owner and CostCenter."
  }
}