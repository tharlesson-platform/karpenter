# Upgrade and Rollback

## Karpenter upgrade

1. Review release notes for the target version.
2. Update `karpenter_version` in `envs/<env>/addons/terraform.tfvars`.
3. Run:

```powershell
terraform -chdir=envs/<env>/addons plan
terraform -chdir=envs/<env>/addons apply
```

4. Validate:

```powershell
kubectl get pods -n karpenter
kubectl get crd | Select-String karpenter
```

## Kubernetes/EKS upgrade

1. Upgrade one environment at a time (`dev -> stage -> prod`).
2. Update `kubernetes_version` in `envs/<env>/infra/terraform.tfvars`.
3. Confirm compatible addon versions in `addon_versions`.
4. Apply infra stack and monitor node group rollouts.

## NodePool tuning rollout

- Update template values in `manifests/env/<env>.env`.
- Re-render and apply manifests:

```powershell
./scripts/render-manifests.ps1 -Environment <env> -UseTerraformOutputs
kubectl apply -f manifests/rendered/<env>
```

## Rollback strategy

### Karpenter rollback

- Revert `karpenter_version` to the previous tested version.
- Re-apply `envs/<env>/addons`.

### NodePool rollback

- Revert manifest templates/environment values in Git.
- Re-render and apply prior manifests.

### EKS rollback

Control plane downgrade is not supported in-place. For major incidents:

- Keep managed baseline capacity healthy.
- Revert addon/NodePool changes first.
- If needed, perform blue/green cluster recovery strategy.

## Safe deployment guidance

- Always test upgrades in `dev` and `stage` before `prod`.
- Keep managed node group capacity sufficient during changes.
- Avoid simultaneous EKS + Karpenter + NodePool disruptive changes in one window.