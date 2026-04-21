# Operations and Observability

## Metrics and scraping

- Helm values enable `serviceMonitor.enabled=true`.
- Integrate with `kube-prometheus-stack` by keeping label `release: kube-prometheus-stack`.

## Logs

Controller logs:

```powershell
kubectl logs -n karpenter deployment/karpenter -f
```

Increase verbosity temporarily by changing `controller_log_level` to `debug` in `envs/<env>/addons/terraform.tfvars` and re-applying addons stack.

## Recommended alerts

Apply the sample rule file:

```powershell
kubectl apply -f manifests/observability/karpenter-alert-rules.yaml
```

It includes:
- Controller unavailable
- High reconcile error rate
- Excessive unschedulable pods

## Daily operational checks

```powershell
kubectl get nodepools
kubectl get ec2nodeclasses
kubectl get nodes -L karpenter.sh/nodepool,karpenter.sh/capacity-type
kubectl get pods -n karpenter -o wide
```

## Spot interruption flow

1. EventBridge captures interruption/rebalance/maintenance/state-change events.
2. Events are pushed to SQS queue.
3. Karpenter controller consumes queue messages.
4. Node disruption is coordinated by Karpenter disruption logic and pod scheduling.

## Troubleshooting quick commands

```powershell
kubectl describe nodepool spot-flexible
kubectl describe ec2nodeclass default-al2023
kubectl get events -A --sort-by=.lastTimestamp | Select-Object -Last 40
aws events list-rules --name-prefix <cluster>-karpenter --region <region>
aws sqs get-queue-url --queue-name <cluster>-karpenter-interruptions --region <region>
```

## Post-deploy checklist

- Karpenter pods running on managed node group (`system`), not Karpenter nodes.
- EC2NodeClass Ready.
- All expected NodePools Ready.
- Scale-up observed from sample workloads.
- Scale-down/consolidation observed after workload removal.
- SQS queue receives interruption events (or at least queue/rules are healthy).
- Alert rules loaded in Prometheus.