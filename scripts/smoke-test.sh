#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/smoke-test.sh [--cleanup]
EOF
}

cleanup="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --cleanup)
      cleanup="true"
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ "${cleanup}" == "true" ]]; then
  kubectl delete -f "${repo_root}/manifests/workloads" --ignore-not-found
  echo "Sample workloads removed."
  exit 0
fi

kubectl apply -f "${repo_root}/manifests/workloads/inflate.yaml"
kubectl apply -f "${repo_root}/manifests/workloads/spot-batch.yaml"
kubectl apply -f "${repo_root}/manifests/workloads/critical-api.yaml"
kubectl apply -f "${repo_root}/manifests/workloads/taint-toleration-demo.yaml"

echo "Sample workloads deployed. Observe new nodes with:"
echo "kubectl get nodes -L karpenter.sh/nodepool,karpenter.sh/capacity-type,kubernetes.io/arch -w"
