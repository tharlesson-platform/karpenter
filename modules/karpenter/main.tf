locals {
  interruption_queue_name = coalesce(var.interruption_queue_name, "${var.cluster_name}-karpenter-interruptions")

  interruption_event_patterns = {
    spot_interruption = jsonencode({
      source      = ["aws.ec2"]
      detail-type = ["EC2 Spot Instance Interruption Warning"]
    })

    rebalance_recommendation = jsonencode({
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance Rebalance Recommendation"]
    })

    scheduled_change = jsonencode({
      source      = ["aws.health"]
      detail-type = ["AWS Health Event"]
      detail = {
        service           = ["EC2"]
        eventTypeCategory = ["scheduledChange"]
      }
    })

    instance_state_change = jsonencode({
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance State-change Notification"]
      detail = {
        state = ["stopping", "stopped", "shutting-down", "terminated"]
      }
    })
  }
}

resource "kubernetes_namespace" "karpenter" {
  metadata {
    name = var.karpenter_namespace

    labels = {
      "app.kubernetes.io/name"       = "karpenter"
      "app.kubernetes.io/managed-by" = "terraform"
      "environment"                  = var.environment
    }
  }
}

resource "aws_sqs_queue" "interruption_dlq" {
  count = var.enable_spot_interruption_handling ? 1 : 0

  name                      = "${local.interruption_queue_name}-dlq"
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600

  tags = merge(
    var.tags,
    {
      "Name" = "${local.interruption_queue_name}-dlq"
    }
  )
}

resource "aws_sqs_queue" "interruption" {
  count = var.enable_spot_interruption_handling ? 1 : 0

  name                       = local.interruption_queue_name
  sqs_managed_sse_enabled    = true
  message_retention_seconds  = var.interruption_queue_retention_seconds
  visibility_timeout_seconds = var.interruption_queue_visibility_timeout_seconds

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.interruption_dlq[0].arn
    maxReceiveCount     = 5
  })

  tags = merge(
    var.tags,
    {
      "Name" = local.interruption_queue_name
    }
  )
}

resource "aws_cloudwatch_event_rule" "interruption" {
  for_each = var.enable_spot_interruption_handling ? local.interruption_event_patterns : {}

  name          = "${var.cluster_name}-karpenter-${replace(each.key, "_", "-")}"
  event_pattern = each.value

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "interruption" {
  for_each = var.enable_spot_interruption_handling ? aws_cloudwatch_event_rule.interruption : {}

  rule      = each.value.name
  target_id = "${each.key}-sqs"
  arn       = aws_sqs_queue.interruption[0].arn
}

data "aws_iam_policy_document" "interruption_queue" {
  count = var.enable_spot_interruption_handling ? 1 : 0

  statement {
    sid       = "AllowEventBridgeToSendMessages"
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.interruption[0].arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"
      values   = [for rule in aws_cloudwatch_event_rule.interruption : rule.arn]
    }
  }
}

resource "aws_sqs_queue_policy" "interruption" {
  count = var.enable_spot_interruption_handling ? 1 : 0

  queue_url = aws_sqs_queue.interruption[0].id
  policy    = data.aws_iam_policy_document.interruption_queue[0].json
}

resource "helm_release" "karpenter_crd" {
  name             = "karpenter-crd"
  namespace        = var.karpenter_namespace
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter-crd"
  version          = var.karpenter_version
  create_namespace = false
  wait             = true
  atomic           = true
  timeout          = 600

  depends_on = [kubernetes_namespace.karpenter]
}

resource "helm_release" "karpenter" {
  name             = "karpenter"
  namespace        = var.karpenter_namespace
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = var.karpenter_version
  create_namespace = false
  wait             = true
  atomic           = true
  timeout          = 600

  values = [file(var.helm_values_path)]

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.controller_role_arn
  }

  set {
    name  = "settings.clusterName"
    value = var.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = var.cluster_endpoint
  }

  set {
    name  = "settings.interruptionQueue"
    value = var.enable_spot_interruption_handling ? aws_sqs_queue.interruption[0].name : ""
  }

  set {
    name  = "logLevel"
    value = var.controller_log_level
  }

  set {
    name  = "replicas"
    value = tostring(var.controller_replicas)
  }

  # Prevents scheduling the Karpenter controller on nodes created by Karpenter itself.
  set {
    name  = "controller.nodeSelector.eks\\.amazonaws\\.com/nodegroup"
    value = var.system_node_group_name
  }

  depends_on = [
    helm_release.karpenter_crd,
    aws_sqs_queue_policy.interruption
  ]
}