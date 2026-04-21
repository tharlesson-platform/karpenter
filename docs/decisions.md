# Architectural Decisions

## Why two Terraform stacks per environment

We split into `infra` and `addons` to avoid bootstrap dependency issues with Kubernetes/Helm providers before the EKS API exists, and to support safer release cadence for platform add-ons.

## Why Access Entries instead of aws-auth

`aws_eks_access_entry` is the modern AWS-managed approach and avoids direct manual management of `aws-auth` ConfigMap for worker node access.

## Why fixed managed node group + Karpenter

- Managed node group provides stable control-plane-adjacent capacity.
- Karpenter provides elastic and cost-efficient scheduling for workloads.
- This prevents controller self-hosting loops and startup deadlocks.

## Why AL2023 and pinned versions

AL2023 provides current hardening and lifecycle posture. AMI alias and chart/Kubernetes versions are pinned and parameterized to avoid uncontrolled drift.

# Trade-offs

- Two-stack deployment is more steps than single stack, but significantly more reliable.
- Using templates + render script for NodePools adds one manifest generation step, but improves GitOps portability and reviewability.
- Restrictive instance requirements improve governance but can reduce immediate capacity options in constrained AZs.

# Future Improvements

1. Add CI pipeline (`terraform fmt`, `validate`, `tflint`, `tfsec`, `kubeconform`).
2. Add OPA/Conftest policy checks for NodePool constraints.
3. Add Argo CD Application manifests for GitOps promotion.
4. Add dedicated NodePool per workload domain/team.
5. Add FinOps dashboards with Karpenter + EC2 cost attribution.

# Common Errors and How to Avoid Them

1. **Controller running on Karpenter nodes**
Set managed node group selector in Helm values and keep baseline capacity.

2. **Using unpinned versions**
Always set explicit versions for Kubernetes, add-ons, Karpenter chart, and AMI alias.

3. **Forgetting discovery tags**
Ensure subnets and security groups have `karpenter.sh/discovery=<cluster-name>`.

4. **Mixing incompatible workload constraints**
If workload selectors/taints do not match NodePool labels/taints, pods remain pending.

5. **No interruption handling for Spot**
Always keep SQS + EventBridge enabled when using Spot NodePools.