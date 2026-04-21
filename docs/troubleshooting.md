# Troubleshooting

## Karpenter pod not scheduling

Checks:

```powershell
kubectl get pods -n karpenter -o wide
kubectl describe pod -n karpenter <pod-name>
kubectl get nodes -L eks.amazonaws.com/nodegroup
```

Fixes:

- Confirm `system_node_group_name` matches actual managed node group label.
- Ensure fixed node group has enough headroom.

## NodePool exists but no nodes are created

Checks:

```powershell
kubectl describe nodepool ondemand-general
kubectl describe ec2nodeclass default-al2023
kubectl logs -n karpenter deployment/karpenter --tail=200
```

Common causes:

- Missing discovery tags on subnets/security groups.
- AMI alias invalid for region.
- EC2 quota/instance availability constraints.
- IAM policy missing `iam:PassRole` or EC2 permissions.

## Nodes fail to join cluster

Checks:

```powershell
aws eks list-access-entries --cluster-name <cluster> --region <region>
```

Fixes:

- Confirm `aws_eks_access_entry` exists for Karpenter node role.
- Validate instance profile and node role policies.

## Spot interruption queue not receiving events

Checks:

```powershell
aws events list-rule-names-by-target --target-arn <queue-arn> --region <region>
aws sqs get-queue-attributes --queue-url <queue-url> --attribute-names All --region <region>
```

Fixes:

- Confirm EventBridge rules are enabled.
- Confirm SQS queue policy allows `events.amazonaws.com` with source rule ARNs.

## Helm release failed

Checks:

```powershell
helm list -n karpenter
helm status karpenter -n karpenter
kubectl get events -n karpenter --sort-by=.lastTimestamp
```

Fixes:

- Validate OIDC/IRSA role annotation.
- Validate chart version exists in OCI registry.
- Re-apply addons stack after fixing values.