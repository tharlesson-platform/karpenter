output "karpenter_namespace" {
  description = "Kubernetes namespace where Karpenter was installed."
  value       = kubernetes_namespace.karpenter.metadata[0].name
}

output "helm_release_name" {
  description = "Helm release name for Karpenter controller."
  value       = helm_release.karpenter.name
}

output "interruption_queue_name" {
  description = "SQS queue name used for interruption handling."
  value       = var.enable_spot_interruption_handling ? aws_sqs_queue.interruption[0].name : null
}

output "interruption_queue_arn" {
  description = "SQS queue ARN used for interruption handling."
  value       = var.enable_spot_interruption_handling ? aws_sqs_queue.interruption[0].arn : null
}

output "interruption_queue_url" {
  description = "SQS queue URL used for interruption handling."
  value       = var.enable_spot_interruption_handling ? aws_sqs_queue.interruption[0].url : null
}

output "interruption_event_rule_arns" {
  description = "EventBridge rules feeding interruption events into SQS."
  value       = { for key, rule in aws_cloudwatch_event_rule.interruption : key => rule.arn }
}