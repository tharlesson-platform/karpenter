param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("dev", "stage", "prod")]
  [string]$Environment,

  [Parameter(Mandatory = $false)]
  [switch]$AutoApprove,

  [Parameter(Mandatory = $false)]
  [switch]$SkipWorkloads
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$infraDir = Join-Path $repoRoot "envs/$Environment/infra"
$addonsDir = Join-Path $repoRoot "envs/$Environment/addons"
$renderScript = Join-Path $PSScriptRoot "render-manifests.ps1"
$renderedManifests = Join-Path $repoRoot "manifests/rendered/$Environment"

$applyArgs = @()
if ($AutoApprove.IsPresent) {
  $applyArgs += "-auto-approve"
}

Write-Host "[1/6] Terraform init/apply for infra"
terraform -chdir=$infraDir init
terraform -chdir=$infraDir plan
terraform -chdir=$infraDir apply @applyArgs

Write-Host "[2/6] Terraform init/apply for addons"
terraform -chdir=$addonsDir init
terraform -chdir=$addonsDir plan
terraform -chdir=$addonsDir apply @applyArgs

Write-Host "[3/6] Updating kubeconfig"
$clusterName = terraform -chdir=$infraDir output -raw cluster_name
$region = terraform -chdir=$infraDir output -raw aws_region
aws eks update-kubeconfig --name $clusterName --region $region

Write-Host "[4/6] Rendering Karpenter manifests"
& $renderScript -Environment $Environment -UseTerraformOutputs

Write-Host "[5/6] Applying NodeClass and NodePools"
kubectl apply -f $renderedManifests

if (-not $SkipWorkloads.IsPresent) {
  Write-Host "[6/6] Applying sample workloads"
  kubectl apply -f (Join-Path $repoRoot "manifests/workloads")
}

Write-Host "Deployment flow completed successfully."