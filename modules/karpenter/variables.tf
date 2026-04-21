variable "environment" {
  description = "Environment name (dev, stage, prod)."
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name."
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster API endpoint used by Karpenter settings."
  type        = string
}

variable "karpenter_namespace" {
  description = "Namespace where Karpenter is installed."
  type        = string
  default     = "karpenter"
}

variable "karpenter_version" {
  description = "Pinned Karpenter Helm chart version."
  type        = string
}

variable "controller_role_arn" {
  description = "IRSA role ARN used by Karpenter controller service account."
  type        = string
}

variable "system_node_group_name" {
  description = "Managed node group name that must host the Karpenter controller."
  type        = string
}

variable "helm_values_path" {
  description = "Path to Helm values YAML file used by the Karpenter chart."
  type        = string
}

variable "controller_replicas" {
  description = "Number of Karpenter controller replicas."
  type        = number
  default     = 2

  validation {
    condition     = var.controller_replicas >= 1
    error_message = "controller_replicas must be >= 1."
  }
}

variable "controller_log_level" {
  description = "Karpenter controller log level."
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.controller_log_level)
    error_message = "controller_log_level must be debug, info, warn, or error."
  }
}

variable "enable_spot_interruption_handling" {
  description = "Whether to create SQS/EventBridge integration for interruption handling."
  type        = bool
  default     = true
}

variable "interruption_queue_name" {
  description = "Optional custom queue name for interruption events."
  type        = string
  default     = null
}

variable "interruption_queue_retention_seconds" {
  description = "SQS message retention period in seconds for the interruption queue."
  type        = number
  default     = 300
}

variable "interruption_queue_visibility_timeout_seconds" {
  description = "SQS visibility timeout for interruption messages."
  type        = number
  default     = 30
}

variable "tags" {
  description = "Standard tags applied to AWS resources."
  type        = map(string)
  default     = {}
}