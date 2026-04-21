#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/deploy.sh --environment <dev|stage|prod> [--auto-approve] [--skip-workloads]
EOF
}

environment=""
auto_approve="false"
skip_workloads="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment)
      environment="${2:-}"
      shift 2
      ;;
    --auto-approve)
      auto_approve="true"
      shift 1
      ;;
    --skip-workloads)
      skip_workloads="true"
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
rendered_manifests="${repo_root}/manifests/rendered/${environment}"
render_script="${repo_root}/scripts/render-manifests.sh"

apply_args=()
if [[ "${auto_approve}" == "true" ]]; then
  apply_args+=("-auto-approve")
fi

echo "[1/6] Terraform init/apply for infra"
terraform -chdir="${infra_dir}" init
terraform -chdir="${infra_dir}" plan
terraform -chdir="${infra_dir}" apply "${apply_args[@]}"

echo "[2/6] Terraform init/apply for addons"
terraform -chdir="${addons_dir}" init
terraform -chdir="${addons_dir}" plan
terraform -chdir="${addons_dir}" apply "${apply_args[@]}"

echo "[3/6] Updating kubeconfig"
cluster_name="$(terraform -chdir="${infra_dir}" output -raw cluster_name)"
region="$(terraform -chdir="${infra_dir}" output -raw aws_region)"
aws eks update-kubeconfig --name "${cluster_name}" --region "${region}"

echo "[4/6] Rendering Karpenter manifests"
"${render_script}" --environment "${environment}" --use-terraform-outputs

echo "[5/6] Applying NodeClass and NodePools"
kubectl apply -f "${rendered_manifests}"

if [[ "${skip_workloads}" != "true" ]]; then
  echo "[6/6] Applying sample workloads"
  kubectl apply -f "${repo_root}/manifests/workloads"
fi

echo "Deployment flow completed successfully."
