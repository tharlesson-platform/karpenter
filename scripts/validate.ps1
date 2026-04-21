param(
  [Parameter(Mandatory = $true)]
  [ValidateSet("dev", "stage", "prod")]
  [string]$Environment
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$infraDir = Join-Path $repoRoot "envs/$Environment/infra"
$addonsDir = Join-Path $repoRoot "envs/$Environment/addons"

$clusterName = terraform -chdir=$infraDir output -raw cluster_name
$region = terraform -chdir=$infraDir output -raw aws_region
$queueName = terraform -chdir=$addonsDir output -raw interruption_queue_name

Write-Host "Cluster: $clusterName"
Write-Host "Region:  $region"
Write-Host "Queue:   $queueName"

Write-Host "\n=== Karpenter pods ==="
kubectl get pods -n karpenter -o wide

Write-Host "\n=== Karpenter CRDs ==="
kubectl get crd | Select-String "karpenter"

Write-Host "\n=== NodePools ==="
kubectl get nodepools

Write-Host "\n=== EC2NodeClasses ==="
kubectl get ec2nodeclasses

Write-Host "\n=== Queue attributes ==="
if ($queueName -and $queueName -ne "null") {
  aws sqs get-queue-attributes --queue-url (aws sqs get-queue-url --queue-name $queueName --region $region --query QueueUrl --output text) --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --region $region
} else {
  Write-Host "Interruption queue is disabled for this environment."
}

Write-Host "\n=== Nodes and labels ==="
kubectl get nodes -L karpenter.sh/nodepool,karpenter.sh/capacity-type,kubernetes.io/arch

Write-Host "\nValidation completed."
