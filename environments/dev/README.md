# environments/dev

Root configuration for the dev environment. This is a composition layer only: it wires modules together and owns state and provider configuration. No resources are declared directly here.

## State

Backend values are supplied at init time so no environment specific data is committed.

```bash
cp backend.hcl.example backend.hcl          # gitignored
cp terraform.tfvars.example terraform.tfvars # gitignored
terraform init -backend-config=backend.hcl
terraform plan
```

State key is `dev/network.tfstate`. Each environment and each layer gets its own key. No workspaces.

## Promotion

Copy this directory to `environments/stg` or `environments/prd` and change the tfvars plus the state key. Module source references stay identical, which is what makes the promotion reviewable in a diff.

## Files

| File | Owns |
|---|---|
| `providers.tf` | Terraform and provider version constraints, provider configuration |
| `backend.tf` | Backend type only, values come from `backend.hcl` |
| `main.tf` | Module composition |
| `variables.tf` | Inputs for this environment |
| `outputs.tf` | Values surfaced to operators and downstream layers |
