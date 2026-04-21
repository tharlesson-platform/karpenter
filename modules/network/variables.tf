variable "cluster_name" {
  description = "EKS cluster name used in discovery tags."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs that Karpenter can use for node provisioning."
  type        = list(string)
  default     = []
}

variable "discovery_security_group_ids" {
  description = "Security groups selected by EC2NodeClass through discovery tags."
  type        = list(string)
  default     = []
}

variable "karpenter_discovery_tag_key" {
  description = "Tag key used by Karpenter resource selectors."
  type        = string
  default     = "karpenter.sh/discovery"
}

variable "tag_subnets_for_karpenter" {
  description = "Whether to tag selected private subnets for Karpenter discovery."
  type        = bool
  default     = true
}

variable "tag_security_groups_for_karpenter" {
  description = "Whether to tag selected security groups for Karpenter discovery."
  type        = bool
  default     = true
}