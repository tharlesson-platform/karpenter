#!/usr/bin/env bash

set -euo pipefail

usage() {
  cat <<'EOF'
Usage: ./scripts/render-manifests.sh --environment <dev|stage|prod> [--infra-dir <path>] [--output-dir <path>] [--use-terraform-outputs]
EOF
}

environment=""
infra_dir=""
output_dir=""
use_terraform_outputs="false"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --environment)
      environment="${2:-}"
      shift 2
      ;;
    --infra-dir)
      infra_dir="${2:-}"
      shift 2
      ;;
    --output-dir)
      output_dir="${2:-}"
      shift 2
      ;;
    --use-terraform-outputs)
      use_terraform_outputs="true"
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
templates_dir="${repo_root}/manifests/templates"
env_file="${repo_root}/manifests/env/${environment}.env"
infra_dir="${infra_dir:-${repo_root}/envs/${environment}/infra}"
output_dir="${output_dir:-${repo_root}/manifests/rendered/${environment}}"

if [[ ! -f "${env_file}" ]]; then
  echo "Environment file not found: ${env_file}" >&2
  exit 1
fi

declare -A vars

while IFS='=' read -r key value; do
  [[ -z "${key}" ]] && continue
  [[ "${key}" =~ ^[[:space:]]*# ]] && continue
  key="$(echo "${key}" | xargs)"
  value="$(echo "${value:-}" | xargs)"
  [[ -z "${key}" ]] && continue
  vars["${key}"]="${value}"
done < "${env_file}"

if [[ "${use_terraform_outputs}" == "true" ]]; then
  echo "Reading terraform outputs from ${infra_dir}"
  cluster_name="$(terraform -chdir="${infra_dir}" output -raw cluster_name)"
  instance_profile_name="$(terraform -chdir="${infra_dir}" output -raw karpenter_node_instance_profile_name)"
  vars["CLUSTER_NAME"]="${cluster_name}"
  vars["KARPENTER_INSTANCE_PROFILE_NAME"]="${instance_profile_name}"
fi

mkdir -p "${output_dir}"

for template in "${templates_dir}"/*.tpl; do
  content="$(cat "${template}")"
  for key in "${!vars[@]}"; do
    token="\${${key}}"
    content="${content//${token}/${vars[$key]}}"
  done
  target_name="$(basename "${template}" .tpl)"
  target_path="${output_dir}/${target_name}"
  printf '%s' "${content}" > "${target_path}"
  echo "Rendered ${target_path}"
done

echo "Manifest rendering complete for environment: ${environment}"
