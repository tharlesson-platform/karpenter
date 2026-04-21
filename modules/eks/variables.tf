variable "cluster_name" {
  description = "EKS cluster name."
  type        = string

  validation {
    condition     = length(var.cluster_name) > 2
    error_message = "cluster_name must have at least 3 characters."
  }
}

variable "kubernetes_version" {
  description = "Pinned Kubernetes version for EKS control plane."
  type        = string
}

variable "authentication_mode" {
  description = "EKS authentication mode. API is recommended for Access Entries."
  type        = string
  default     = "API"

  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP", "CONFIG_MAP"], var.authentication_mode)
    error_message = "authentication_mode must be API, API_AND_CONFIG_MAP, or CONFIG_MAP."
  }
}

variable "enable_cluster_creator_admin_permissions" {
  description = "Grant initial admin permissions to the IAM principal that creates the cluster."
  type        = bool
  default     = true
}

variable "cluster_endpoint_private_access" {
  description = "Whether the Amazon EKS private API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "cluster_endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = false
}

variable "cluster_enabled_log_types" {
  description = "EKS control plane logs to enable."
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "cluster_log_retention_days" {
  description = "CloudWatch retention for control plane logs."
  type        = number
  default     = 30
}

variable "vpc_id" {
  description = "Existing VPC ID where the EKS cluster will run."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for control plane ENIs and worker nodes."
  type        = list(string)

  validation {
    condition     = length(var.private_subnet_ids) >= 2
    error_message = "At least two private subnets are required."
  }
}

variable "cluster_security_group_additional_ids" {
  description = "Optional additional security groups attached to the EKS control plane."
  type        = list(string)
  default     = []
}

variable "system_node_group" {
  description = "Fixed managed node group used by cluster-critical workloads (including Karpenter controller)."
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

  default = {
    name            = "system"
    desired_size    = 2
    min_size        = 2
    max_size        = 3
    instance_types  = ["m6i.large"]
    ami_type        = "AL2023_x86_64_STANDARD"
    disk_size       = 80
    capacity_type   = "ON_DEMAND"
    max_unavailable = 1
    labels          = {}
  }
}

variable "addon_versions" {
  description = "Pinned EKS addon versions compatible with the selected Kubernetes version."
  type = object({
    coredns            = string
    kube_proxy         = string
    vpc_cni            = string
    pod_identity_agent = string
  })
}

variable "tags" {
  description = "Standard tags applied to all resources."
  type        = map(string)
  default     = {}
}