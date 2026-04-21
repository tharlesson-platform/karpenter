# Costs and Capacity Strategy

## Strategy implemented

- Fixed managed node group for core services (predictable baseline cost).
- Karpenter NodePools for burst and flexible demand.
- Spot pool (`spot-flexible`) for stateless and retry-friendly workloads.
- On-demand critical pool with strict taints for sensitive services.

## Cost controls

- NodePool `limits` cap total provisioned CPU/memory.
- Consolidation enabled to reduce idle/fragmented nodes.
- `expireAfter` forces periodic node recycling and prevents long-lived drift.
- Instance constraints avoid legacy/inefficient families.

## Recommended workload placement

- Critical APIs/stateful gateways: `critical-ondemand`.
- Core production stateless services: `ondemand-general`.
- Batch/async/CI workers: `spot-flexible` with tolerations.

## Example selectors/tolerations

```yaml
nodeSelector:
  capacity-tier: spot
tolerations:
  - key: spot-only
    operator: Equal
    value: "true"
    effect: NoSchedule
```

```yaml
nodeSelector:
  workload-tier: critical
tolerations:
  - key: critical-only
    operator: Equal
    value: "true"
    effect: NoSchedule
```

## Instance family governance

Current templates enforce:

- Allowed categories/families/generation/hypervisor
- Spot pool graviton-first (`arm64`) for better price/perf
- Critical pool x86-focused for compatibility-sensitive workloads

Adjust these in `manifests/templates/nodepool-*.yaml.tpl`.