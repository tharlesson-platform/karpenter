variable "aws_region" {
  description = "AWS region where the cluster and Karpenter resources are deployed."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_arn" {
  description = "EKS cluster ARN used for IAM policy scoping."
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS cluster."
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC issuer URL from EKS cluster."
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace where the Karpenter controller service account runs."
  type        = string
  default     = "karpenter"
}

variable "karpenter_service_account_name" {
  description = "Service account name used by the Karpenter controller."
  type        = string
  default     = "karpenter"
}

variable "interruption_queue_name" {
  description = "SQS queue name used by interruption handling. If null, queue permissions are omitted."
  type        = string
  default     = null
}

variable "permissions_boundary_arn" {
  description = "Optional IAM permissions boundary for enterprise governance."
  type        = string
  default     = null
}

variable "controller_role_name" {
  description = "Optional override for the controller IAM role name."
  type        = string
  default     = null
}

variable "node_role_name" {
  description = "Optional override for the Karpenter node role name."
  type        = string
  default     = null
}

variable "node_instance_profile_name" {
  description = "Optional override for Karpenter node instance profile name."
  type        = string
  default     = null
}

variable "create_node_access_entry" {
  description = "Whether to create EKS access entry for Karpenter EC2 nodes."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Standard tags applied to IAM resources."
  type        = map(string)
  default     = {}
}
