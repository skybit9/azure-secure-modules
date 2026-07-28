# Onboarding

## Prerequisites

- Terraform 1.15 or later
- Azure CLI
- pre-commit
- opa and conftest for policy work

## First hour

```bash
git clone https://github.com/skybit9/azure-secure-modules.git
cd azure-secure-modules
pre-commit install

# no Azure account needed for any of this
cd modules/azure-network
terraform init -backend=false
terraform validate
terraform test

cd ../../
opa test policies -v
```

Everything above runs offline. The module tests use `mock_provider`, so the full apply path is exercised without a subscription.

## When you do have a subscription

```bash
export SUBSCRIPTION_ID=<id>
export STATE_SA=sttfstate<unique>
export GITHUB_ORG=skybit9
./scripts/bootstrap/bootstrap.sh
```

Then set repository secrets and variables as printed, and set the repository variable `AZURE_ENABLED` to `true`. Until that variable is set, the plan and apply jobs skip and the pipeline stays green.

## Adding a module

1. Copy the shape of `modules/azure-observability`, it is the smallest complete example
2. Required files: `versions.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `README.md`, `examples/`, `tests/`
3. Every security relevant input needs a `validation` block
4. Every resource that supports diagnostic settings gets one
5. Add the module name to the matrix in `.github/workflows/terraform-ci.yml`
6. Add a Conftest policy under `policies/` if the guardrail needs whole plan context
