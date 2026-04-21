# Contributing

## Fluxo recomendado

1. Crie uma branch curta a partir de `main`.
2. Rode `terraform fmt -recursive` antes de abrir PR.
3. Valide os scripts Bash e PowerShell que forem alterados.
4. Atualize `README.md` ou `docs/` quando o fluxo operacional mudar.

## Regras praticas

- preserve compatibilidade entre os scripts `.ps1` e `.sh`;
- mantenha `NodePool` e `EC2NodeClass` como APIs principais;
- nao versione `terraform.tfstate`, `terraform.tfvars` ou manifests renderizados;
- prefira mudancas pequenas e reversiveis em stacks de `infra` e `addons`.
