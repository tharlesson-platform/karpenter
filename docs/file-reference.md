# File Reference

## Root

- `.gitignore`: ignores state files and rendered artifacts.
- `README.md`: consolidated guide, architecture summary, command order, checklist.

## Modules

- `modules/eks/versions.tf`: provider/version constraints for EKS module.
- `modules/eks/variables.tf`: input contract for cluster and node group settings.
- `modules/eks/main.tf`: EKS cluster, managed node group, OIDC, addons, tags.
- `modules/eks/outputs.tf`: exports cluster IDs/endpoints/certs/SG IDs.

- `modules/network/versions.tf`: provider/version constraints.
- `modules/network/variables.tf`: subnet/SG discovery tagging inputs.
- `modules/network/main.tf`: tags private subnets and security groups for Karpenter discovery.
- `modules/network/outputs.tf`: exports tagged resources.

- `modules/iam/versions.tf`: provider/version constraints.
- `modules/iam/variables.tf`: IAM input contract (IRSA, node role, queue name, boundaries).
- `modules/iam/main.tf`: IRSA role/policy, node role/profile, access entry.
- `modules/iam/outputs.tf`: exports role/profile/policy/access entry IDs.

- `modules/karpenter/versions.tf`: provider constraints for AWS/Helm/Kubernetes.
- `modules/karpenter/variables.tf`: chart/queue/controller config inputs.
- `modules/karpenter/main.tf`: SQS/EventBridge + Helm install (CRDs + controller).
- `modules/karpenter/outputs.tf`: exports release and interruption infrastructure outputs.

## Environments

Each environment has two stacks:

- `envs/<env>/infra/*`: EKS + IAM + discovery tags.
- `envs/<env>/addons/*`: Karpenter Helm + interruption handling.

For each stack:

- `backend.tf`: backend declaration (`s3`).
- `versions.tf`: Terraform/provider version constraints.
- `providers.tf`: provider configuration.
- `variables.tf`: validated inputs.
- `main.tf`: module composition.
- `outputs.tf`: consumable outputs.
- `terraform.tfvars.example`: practical pinned example values.

## Helm values

- `helm-values/karpenter-values-dev.yaml`: dev tuning.
- `helm-values/karpenter-values-stage.yaml`: stage tuning.
- `helm-values/karpenter-values-prod.yaml`: production tuning.

## Manifests

- `manifests/templates/ec2nodeclass-al2023.yaml.tpl`: AL2023 node class with tags/disks/IMDSv2.
- `manifests/templates/nodepool-ondemand.yaml.tpl`: general on-demand node pool.
- `manifests/templates/nodepool-spot.yaml.tpl`: Spot graviton-focused node pool.
- `manifests/templates/nodepool-critical.yaml.tpl`: tainted critical on-demand node pool.

- `manifests/env/*.env`: environment-specific values used in template rendering.
- `manifests/workloads/*.yaml`: sample workloads for scale and placement tests.
- `manifests/observability/karpenter-alert-rules.yaml`: sample Prometheus alerts.
- `manifests/README.md`: render/apply instructions.

## Scripts

- `scripts/render-manifests.ps1`: renders templates to `manifests/rendered/<env>`.
- `scripts/deploy.ps1`: end-to-end deploy helper.
- `scripts/validate.ps1`: post-deploy checks.
- `scripts/smoke-test.ps1`: load/placement test workloads.

## Docs

- `docs/architecture.md`: architecture and flow.
- `docs/deployment-guide.md`: deployment steps in order.
- `docs/operations.md`: metrics/logs/alerting/ops checks.
- `docs/upgrade-rollback.md`: upgrade and rollback procedures.
- `docs/costs-and-capacity.md`: capacity and cost controls.
- `docs/troubleshooting.md`: failure scenarios and remediations.
- `docs/decisions.md`: decisions, trade-offs, future improvements, common errors.
- `docs/file-reference.md`: this file.
- `docs/project-dump.md`: complete file-by-file content dump of the repository.
