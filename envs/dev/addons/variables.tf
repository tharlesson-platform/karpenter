variable "aws_region" {
  description = "AWS region for this environment."
  type        = string
}

variable "infra_state_bucket" {
  description = "S3 bucket containing infra stack state."
  type        = string
}

variable "infra_state_key" {
  description = "S3 key for infra stack state file."
  type        = string
}

variable "infra_state_region" {
  description = "AWS region of the infra state S3 bucket."
  type        = string
}

variable "infra_state_lock_table" {
  description = "Optional DynamoDB table used by infra stack state locking."
  type        = string
  default     = null
}

variable "karpenter_namespace" {
  description = "Namespace for Karpenter controller."
  type        = string
  default     = "karpenter"
}

variable "karpenter_version" {
  description = "Pinned Karpenter Helm chart version."
  type        = string
  default     = "1.8.2"
}

variable "controller_replicas" {
  description = "Number of Karpenter controller replicas."
  type        = number
  default     = 2
}

variable "controller_log_level" {
  description = "Controller log level."
  type        = string
  default     = "info"
}

variable "enable_spot_interruption_handling" {
  description = "Create EventBridge and SQS resources for interruption handling."
  type        = bool
  default     = true
}

variable "helm_values_path" {
  description = "Optional absolute or relative path to Karpenter Helm values file."
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