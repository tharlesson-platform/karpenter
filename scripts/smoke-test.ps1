param(
  [Parameter(Mandatory = $false)]
  [switch]$Cleanup
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ($Cleanup.IsPresent) {
  kubectl delete -f (Join-Path $repoRoot "manifests/workloads") --ignore-not-found
  Write-Host "Sample workloads removed."
  exit 0
}

kubectl apply -f (Join-Path $repoRoot "manifests/workloads/inflate.yaml")
kubectl apply -f (Join-Path $repoRoot "manifests/workloads/spot-batch.yaml")
kubectl apply -f (Join-Path $repoRoot "manifests/workloads/critical-api.yaml")
kubectl apply -f (Join-Path $repoRoot "manifests/workloads/taint-toleration-demo.yaml")

Write-Host "Sample workloads deployed. Observe new nodes with:"
Write-Host "kubectl get nodes -L karpenter.sh/nodepool,karpenter.sh/capacity-type,kubernetes.io/arch -w"