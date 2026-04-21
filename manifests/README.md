# Karpenter Manifests

This folder contains production-ready Karpenter manifests using **NodePool** and **EC2NodeClass** APIs only.

## Structure

- `templates/`: environment-parameterized templates (`*.yaml.tpl`)
- `env/`: per-environment values used by the render script
- `rendered/`: generated manifests ready to apply
- `workloads/`: practical workloads for scale-up/scale-down validation
- `observability/`: example Prometheus alert rules

## Render manifests

```powershell
./scripts/render-manifests.ps1 -Environment dev -UseTerraformOutputs
```

This command reads:

1. `manifests/env/dev.env`
2. Terraform outputs from `envs/dev/infra` (cluster name and instance profile), when `-UseTerraformOutputs` is used.

Generated files:

- `manifests/rendered/dev/ec2nodeclass-al2023.yaml`
- `manifests/rendered/dev/nodepool-ondemand.yaml`
- `manifests/rendered/dev/nodepool-spot.yaml`
- `manifests/rendered/dev/nodepool-critical.yaml`

## Apply manifests

```powershell
kubectl apply -f manifests/rendered/dev
```

## Validate

```powershell
kubectl get ec2nodeclasses
kubectl get nodepools
kubectl get nodes -L karpenter.sh/nodepool,karpenter.sh/capacity-type,kubernetes.io/arch
```