output "environment" {
  description = "Environment name."
  value       = local.environment
}

output "karpenter_namespace" {
  description = "Namespace where Karpenter was installed."
  value       = module.karpenter.karpenter_namespace
}

output "karpenter_helm_release" {
  description = "Helm release name for Karpenter controller."
  value       = module.karpenter.helm_release_name
}

output "interruption_queue_name" {
  description = "SQS queue receiving interruption events."
  value       = module.karpenter.interruption_queue_name
}

output "interruption_queue_arn" {
  description = "SQS queue ARN receiving interruption events."
  value       = module.karpenter.interruption_queue_arn
}

output "interruption_event_rule_arns" {
  description = "EventBridge rules that send interruption events to SQS."
  value       = module.karpenter.interruption_event_rule_arns
}