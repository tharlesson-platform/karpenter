locals {
  oidc_provider_hostpath      = replace(var.oidc_provider_url, "https://", "")
  service_account_subject     = "system:serviceaccount:${var.karpenter_namespace}:${var.karpenter_service_account_name}"
  controller_role_name        = coalesce(var.controller_role_name, "${var.cluster_name}-karpenter-controller")
  node_role_name              = coalesce(var.node_role_name, "${var.cluster_name}-karpenter-node")
  node_instance_profile_name  = coalesce(var.node_instance_profile_name, "${var.cluster_name}-karpenter-node")
  interruption_queue_arn      = var.interruption_queue_name == null ? null : "arn:aws:sqs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:${var.interruption_queue_name}"
}

data "aws_caller_identity" "current" {}

############################
# Karpenter Controller IRSA
############################

data "aws_iam_policy_document" "controller_trust" {
  statement {
    sid     = "AllowAssumeRoleWithOIDC"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider_hostpath}:sub"
      values   = [local.service_account_subject]
    }
  }
}

resource "aws_iam_role" "karpenter_controller" {
  name                 = local.controller_role_name
  assume_role_policy   = data.aws_iam_policy_document.controller_trust.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

# This policy intentionally separates read-only discovery from mutating EC2 actions.
# Mutating actions are constrained by cluster and nodepool tags.
data "aws_iam_policy_document" "controller_permissions" {
  # Read-only AWS APIs used for scheduling decisions and node class resolution.
  statement {
    sid = "AllowEC2ReadForScheduling"
    actions = [
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceTypeOfferings",
      "ec2:DescribeInstanceTypes",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeLaunchTemplateVersions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSpotPriceHistory",
      "ec2:DescribeSubnets",
      "ec2:GetInstanceTypesFromInstanceRequirements"
    ]
    resources = ["*"]
  }

  # Node launch actions used by Karpenter provisioning flow.
  statement {
    sid = "AllowScopedEC2LaunchActions"
    actions = [
      "ec2:CreateFleet",
      "ec2:CreateLaunchTemplate",
      "ec2:CreateTags",
      "ec2:RunInstances"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  # Node termination and launch template cleanup, restricted to Karpenter-owned resources.
  statement {
    sid = "AllowScopedEC2DeletionActions"
    actions = [
      "ec2:DeleteLaunchTemplate",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/kubernetes.io/cluster/${var.cluster_name}"
      values   = ["owned"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/karpenter.sh/nodepool"
      values   = ["*"]
    }
  }

  # Required when EC2 instances are launched with the Karpenter node IAM role.
  statement {
    sid       = "AllowPassKarpenterNodeRole"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.karpenter_node.arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ec2.amazonaws.com"]
    }
  }

  # Karpenter resolves cluster endpoint and CA data directly from EKS API.
  statement {
    sid       = "AllowDescribeEKSCluster"
    actions   = ["eks:DescribeCluster"]
    resources = [var.cluster_arn]
  }

  # Public pricing API is used by Karpenter for cost-aware scheduling.
  statement {
    sid       = "AllowPricingRead"
    actions   = ["pricing:GetProducts"]
    resources = ["*"]
  }

  # SSM public parameters are used to resolve EKS-optimized AL2023 AMIs.
  statement {
    sid       = "AllowSSMParameterRead"
    actions   = ["ssm:GetParameter"]
    resources = ["arn:aws:ssm:${var.aws_region}::parameter/aws/service/*"]
  }

  dynamic "statement" {
    for_each = local.interruption_queue_arn == null ? [] : [local.interruption_queue_arn]
    content {
      sid = "AllowInterruptionQueueConsumption"
      actions = [
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ReceiveMessage"
      ]
      resources = [statement.value]
    }
  }
}

resource "aws_iam_policy" "karpenter_controller" {
  name        = "${var.cluster_name}-karpenter-controller"
  description = "Least-privilege permissions for Karpenter controller in ${var.cluster_name}."
  policy      = data.aws_iam_policy_document.controller_permissions.json
  tags        = var.tags
}

resource "aws_iam_role_policy_attachment" "karpenter_controller" {
  role       = aws_iam_role.karpenter_controller.name
  policy_arn = aws_iam_policy.karpenter_controller.arn
}

############################
# Karpenter Node Role
############################

data "aws_iam_policy_document" "node_trust" {
  statement {
    sid     = "AllowEC2AssumeRole"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "karpenter_node" {
  name                 = local.node_role_name
  assume_role_policy   = data.aws_iam_policy_document.node_trust.json
  permissions_boundary = var.permissions_boundary_arn
  tags                 = var.tags
}

locals {
  karpenter_node_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

resource "aws_iam_role_policy_attachment" "karpenter_node" {
  for_each = toset(local.karpenter_node_managed_policies)

  role       = aws_iam_role.karpenter_node.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "karpenter_node" {
  name = local.node_instance_profile_name
  role = aws_iam_role.karpenter_node.name
  tags = var.tags
}

# Access Entry replaces legacy aws-auth for EC2 worker node registration.
resource "aws_eks_access_entry" "karpenter_node" {
  count = var.create_node_access_entry ? 1 : 0

  cluster_name  = var.cluster_name
  principal_arn = aws_iam_role.karpenter_node.arn
  type          = "EC2_LINUX"
  tags          = var.tags
}
