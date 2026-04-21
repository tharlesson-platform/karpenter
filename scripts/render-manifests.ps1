param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("dev", "stage", "prod")]
  [string]$Environment,

  [Parameter(Mandatory = $false)]
  [string]$InfraDir = "",

  [Parameter(Mandatory = $false)]
  [string]$OutputDir = "",

  [Parameter(Mandatory = $false)]
  [switch]$UseTerraformOutputs
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$templatesDir = Join-Path $repoRoot "manifests/templates"
$envFile = Join-Path $repoRoot "manifests/env/$Environment.env"

if ([string]::IsNullOrWhiteSpace($InfraDir)) {
  $InfraDir = Join-Path $repoRoot "envs/$Environment/infra"
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
  $OutputDir = Join-Path $repoRoot "manifests/rendered/$Environment"
}

if (-not (Test-Path $envFile)) {
  throw "Environment file not found: $envFile"
}

function Read-DotEnv {
  param([string]$Path)

  $values = @{}
  foreach ($line in Get-Content $Path) {
    $trimmed = $line.Trim()
    if ($trimmed -eq "" -or $trimmed.StartsWith("#")) {
      continue
    }

    $parts = $trimmed -split "=", 2
    if ($parts.Count -ne 2) {
      continue
    }

    $key = $parts[0].Trim()
    $val = $parts[1].Trim()
    $values[$key] = $val
  }

  return $values
}

$vars = Read-DotEnv -Path $envFile

if ($UseTerraformOutputs.IsPresent) {
  Write-Host "Reading terraform outputs from $InfraDir"
  $tfOutput = terraform -chdir=$InfraDir output -json | ConvertFrom-Json

  if ($tfOutput.cluster_name.value) {
    $vars["CLUSTER_NAME"] = $tfOutput.cluster_name.value
  }

  if ($tfOutput.karpenter_node_instance_profile_name.value) {
    $vars["KARPENTER_INSTANCE_PROFILE_NAME"] = $tfOutput.karpenter_node_instance_profile_name.value
  }
}

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

Get-ChildItem -Path $templatesDir -Filter "*.tpl" | ForEach-Object {
  $content = Get-Content $_.FullName -Raw

  foreach ($entry in $vars.GetEnumerator()) {
    $token = "${" + $entry.Key + "}"
    $content = $content.Replace($token, $entry.Value)
  }

  $targetName = $_.Name -replace "\.tpl$", ""
  $targetPath = Join-Path $OutputDir $targetName
  Set-Content -Path $targetPath -Value $content -NoNewline
  Write-Host "Rendered $targetPath"
}

Write-Host "Manifest rendering complete for environment: $Environment"
