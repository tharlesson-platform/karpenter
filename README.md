# Production-Ready EKS + Karpenter (Terraform)

This repository delivers a production-oriented implementation of **Amazon EKS + Karpenter** using:

- Terraform as primary IaC
- Helm (via Terraform provider) for Karpenter installation
- Current Karpenter APIs only: **NodePool** and **EC2NodeClass**
- No legacy `Provisioner` or `AWSNodeTemplate`

## What this implementation guarantees

- Fixed, minimum managed node group for critical cluster components
- Karpenter controller kept off Karpenter-managed nodes
- Spot interruption handling with SQS + EventBridge
- IAM least privilege with IRSA and explicit node role
- Pinned and parameterized versions (Kubernetes, addons, Karpenter, AMI alias)
- Environment isolation for `dev`, `stage`, `prod`

## Repository tree

```text
.
+-- .gitignore
+-- README.md
+-- modules
�   +-- eks
�   �   +-- main.tf
�   �   +-- outputs.tf
�   �   +-- variables.tf
�   �   +-- versions.tf
�   +-- iam
�   �   +-- main.tf
�   �   +-- outputs.tf
�   �   +-- variables.tf
�   �   +-- versions.tf
�   +-- karpenter
�   �   +-- main.tf
�   �   +-- outputs.tf
�   �   +-- variables.tf
�   �   +-- versions.tf
�   +-- network
�       +-- main.tf
�       +-- outputs.tf
�       +-- variables.tf
�       +-- versions.tf
+-- envs
�   +-- dev
�   �   +-- infra
�   �   �   +-- backend.tf
�   �   �   +-- main.tf
�   �   �   +-- outputs.tf
�   �   �   +-- providers.tf
�   �   �   +-- terraform.tfvars.example
�   �   �   +-- variables.tf
�   �   �   +-- versions.tf
�   �   +-- addons
�   �       +-- backend.tf
�   �       +-- main.tf
�   �       +-- outputs.tf
�   �       +-- providers.tf
�   �       +-- terraform.tfvars.example
�   �       +-- variables.tf
�   �       +-- versions.tf
�   +-- stage
�   �   +-- infra (same file set as dev)
�   �   +-- addons (same file set as dev)
�   +-- prod
�       +-- infra (same file set as dev)
�       +-- addons (same file set as dev)
+-- helm-values
�   +-- karpenter-values-dev.yaml
�   +-- karpenter-values-stage.yaml
�   +-- karpenter-values-prod.yaml
+-- manifests
�   +-- README.md
�   +-- env
�   �   +-- dev.env
�   �   +-- stage.env
�   �   +-- prod.env
�   +-- observability
�   �   +-- karpenter-alert-rules.yaml
�   +-- rendered
�   �   +-- .gitkeep
�   +-- templates
�   �   +-- ec2nodeclass-al2023.yaml.tpl
�   �   +-- nodepool-critical.yaml.tpl
�   �   +-- nodepool-ondemand.yaml.tpl
�   �   +-- nodepool-spot.yaml.tpl
�   +-- workloads
�       +-- critical-api.yaml
�       +-- inflate.yaml
�       +-- spot-batch.yaml
�       +-- taint-toleration-demo.yaml
+-- scripts
�   +-- deploy.ps1
�   +-- render-manifests.ps1
�   +-- smoke-test.ps1
�   +-- validate.ps1
+-- docs
    +-- architecture.md
    +-- costs-and-capacity.md
    +-- decisions.md
    +-- deployment-guide.md
    +-- operations.md
    +-- troubleshooting.md
    +-- upgrade-rollback.md
```

## File roles (quick map)

- `modules/eks`: EKS cluster, OIDC, fixed managed node group, addon pinning.
- `modules/network`: applies Karpenter discovery tags to existing subnets/SGs.
- `modules/iam`: IRSA for controller, Karpenter node role/instance profile, EKS access entry.
- `modules/karpenter`: Karpenter Helm install + CRDs + Spot interruption infrastructure.
- `envs/*/infra`: foundational stack for each environment.
- `envs/*/addons`: add-on stack for Karpenter and interruption queue/rules.
- `helm-values/*`: chart tuning by environment.
- `manifests/templates`: EC2NodeClass/NodePool templates (current Karpenter APIs).
- `manifests/workloads`: practical test workloads for scale behavior.
- `scripts/*`: deployment/render/validation automation.
- `docs/*`: architecture, operations, upgrades, troubleshooting, governance rationale.

## Exact execution order

### 0) Copy example tfvars

```powershell
Copy-Item envs/dev/infra/terraform.tfvars.example envs/dev/infra/terraform.tfvars
Copy-Item envs/dev/addons/terraform.tfvars.example envs/dev/addons/terraform.tfvars
```

### 1) Deploy infra stack

```powershell
terraform -chdir=envs/dev/infra init -backend-config="bucket=<state-bucket>" -backend-config="key=karpenter/dev/infra/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="dynamodb_table=<lock-table>"
terraform -chdir=envs/dev/infra plan
terraform -chdir=envs/dev/infra apply
```

### 2) Deploy addons stack

```powershell
terraform -chdir=envs/dev/addons init -backend-config="bucket=<state-bucket>" -backend-config="key=karpenter/dev/addons/terraform.tfstate" -backend-config="region=us-east-1" -backend-config="dynamodb_table=<lock-table>"
terraform -chdir=envs/dev/addons plan
terraform -chdir=envs/dev/addons apply
```

### 3) Configure kubeconfig

```powershell
$cluster = terraform -chdir=envs/dev/infra output -raw cluster_name
$region  = terraform -chdir=envs/dev/infra output -raw aws_region
aws eks update-kubeconfig --name $cluster --region $region
```

### 4) Render and apply Karpenter manifests

```powershell
./scripts/render-manifests.ps1 -Environment dev -UseTerraformOutputs
kubectl apply -f manifests/rendered/dev
```

Equivalent Bash flow:

```bash
./scripts/render-manifests.sh --environment dev --use-terraform-outputs
kubectl apply -f manifests/rendered/dev
```

### 5) Optional scale tests

```powershell
./scripts/smoke-test.ps1
```

Equivalent Bash flow:

```bash
./scripts/smoke-test.sh
```

### 6) Validation

```powershell
./scripts/validate.ps1 -Environment dev
```

Equivalent Bash flow:

```bash
./scripts/validate.sh --environment dev
```

## Cross-platform operational scripts

The repository now includes both PowerShell and Bash entrypoints for the same operational flows:

- `scripts/deploy.{ps1,sh}`
- `scripts/render-manifests.{ps1,sh}`
- `scripts/smoke-test.{ps1,sh}`
- `scripts/validate.{ps1,sh}`

This makes the repository easier to use in Windows workstations, Linux runners and GitHub Actions.

## CI baseline

GitHub Actions now validates:

- `terraform fmt -check -recursive`;
- shell syntax for all `scripts/*.sh`;
- Terraform validation for all modules and environment stacks;
- required manifest inputs for rendered NodePools and EC2NodeClasses.

### Validação local isolada

O workflow usa uma VM ARM64 efêmera, label exclusiva `karpenter-run-<runID>`,
checkout do SHA exato e actions fixadas por commit. Terraform 1.15.9 mantém
as validações dos dez diretórios, sem backend: `init -backend=false` e
`validate`, além de formatação, sintaxe shell e presença dos manifests.
Não executa `plan`, `apply`, scripts de deploy ou leitura de estado remoto.
Esses comandos não demonstram que um ambiente AWS real esteja correto.

O job não recebe credenciais AWS ou de artifacts; metadata EC2 fica desabilitada
e os arquivos de configuração/credenciais apontam para `/dev/null`. A VM deve
comprovar seu marker e ausência de mounts do host/agente SSH. Sem fallback
hosted: o novo perfil precisa de revisão e admissão explícita pelo controlador
local antes de registrar o runner. Até esse aceite, os jobs aguardam na fila.
Downloads de Terraform/providers usam apenas fontes públicas. Nenhuma licença,
cobrança ou alteração em cloud é parte desta migração.

## Spot interruption handling (implemented)

EventBridge rules forward these events to SQS:

- `EC2 Spot Instance Interruption Warning`
- `EC2 Instance Rebalance Recommendation`
- `AWS Health Event` (EC2 scheduled changes)
- `EC2 Instance State-change Notification`

Karpenter consumes the queue and reacts to disruptions.

## NodePool strategy included

- `critical-ondemand`: tainted, on-demand only, x86 families for compatibility-critical workloads.
- `ondemand-general`: mixed amd64/arm64 for predictable non-critical services.
- `spot-flexible`: graviton-first Spot pool for cost-optimized flexible workloads.

## Security and governance highlights

- IRSA for Karpenter controller
- Scoped IAM policy with tag-based controls for EC2 mutations
- No Node Termination Handler (Karpenter-native interruption handling is used)
- SQS SSE enabled
- IMDSv2 required on Karpenter nodes
- Mandatory default tags validated in Terraform variables

## Validation checklist (post deploy)

- `kubectl get pods -n karpenter` shows healthy replicas.
- Karpenter pods run on fixed managed node group.
- `kubectl get ec2nodeclasses` and `kubectl get nodepools` show Ready.
- Spot queue/rules exist and are active.
- Workloads scale nodes up and down as expected.
- Critical workload remains on `critical-ondemand` only.

## Upgrade and rollback

See: `docs/upgrade-rollback.md`

## Documentation index

- Architecture: `docs/architecture.md`
- Deployment guide: `docs/deployment-guide.md`
- Operations: `docs/operations.md`
- Cost/capacity strategy: `docs/costs-and-capacity.md`
- Troubleshooting: `docs/troubleshooting.md`
- Decisions, trade-offs, future improvements, common errors: `docs/decisions.md`
- File-by-file reference: `docs/file-reference.md`
- Full file contents dump: `docs/project-dump.md`

## Architectural decisions

Summarized in `docs/decisions.md`:

- two-stack model (`infra` + `addons`)
- Access Entries instead of legacy `aws-auth` dependency
- fixed baseline + elastic Karpenter capacity
- AL2023 + pinned/parameterized versions

## Trade-offs

Summarized in `docs/decisions.md`:

- more deployment steps, but safer bootstrap and upgrades
- templates/render step, but better GitOps portability
- stricter instance constraints, but stronger governance

## Future improvements

Summarized in `docs/decisions.md`:

- CI gates (`tflint`, `tfsec`, `kubeconform`)
- policy-as-code guardrails
- GitOps promotion flow with Argo CD
- enhanced FinOps dashboards

## Common errors and how to avoid

Summarized in `docs/decisions.md`:

- wrong discovery tags
- unpinned versions
- selector/taint mismatches
- missing Spot interruption setup
- controller accidentally scheduled on elastic nodes
