#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/validate.sh --environment <dev|stage|prod>
EOF
}

environment=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment)
      environment="${2:-}"
      shift 2
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

if [[ -z "${environment}" ]]; then
  echo "--environment is required" >&2
  usage >&2
  exit 1
fi

case "${environment}" in
  dev|stage|prod) ;;
  *)
    echo "Environment must be one of: dev, stage, prod" >&2
    exit 1
    ;;
esac

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
infra_dir="${repo_root}/envs/${environment}/infra"
addons_dir="${repo_root}/envs/${environment}/addons"

cluster_name="$(terraform -chdir="${infra_dir}" output -raw cluster_name)"
region="$(terraform -chdir="${infra_dir}" output -raw aws_region)"
queue_name="$(terraform -chdir="${addons_dir}" output -raw interruption_queue_name)"

echo "Cluster: ${cluster_name}"
echo "Region:  ${region}"
echo "Queue:   ${queue_name}"

echo
echo "=== Karpenter pods ==="
kubectl get pods -n karpenter -o wide

echo
echo "=== Karpenter CRDs ==="
kubectl get crd | grep karpenter || true

echo
echo "=== NodePools ==="
kubectl get nodepools

echo
echo "=== EC2NodeClasses ==="
kubectl get ec2nodeclasses

echo
echo "=== Queue attributes ==="
if [[ -n "${queue_name}" && "${queue_name}" != "null" ]]; then
  queue_url="$(aws sqs get-queue-url --queue-name "${queue_name}" --region "${region}" --query QueueUrl --output text)"
  aws sqs get-queue-attributes \
    --queue-url "${queue_url}" \
    --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
    --region "${region}"
else
  echo "Interruption queue is disabled for this environment."
fi

echo
echo "=== Nodes and labels ==="
kubectl get nodes -L karpenter.sh/nodepool,karpenter.sh/capacity-type,kubernetes.io/arch

echo
echo "Validation completed."
