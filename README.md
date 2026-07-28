# azure-secure-modules

Terraform modules for Azure built for governed environments. Deny by default networking, mandatory governance tags, diagnostics wired in from the first apply, and policy as code gates on every pull request.

The goal is that the audit evidence is a by product of the deployment rather than something assembled by hand months later.

Everything in this repository can be validated and tested without an Azure subscription.

## Layout

```
.
├── modules/                          reusable modules, each self contained
│   ├── azure-network/
│   │   ├── main.tf  nsg.tf  diagnostics.tf  locals.tf
│   │   ├── variables.tf  outputs.tf  versions.tf
│   │   ├── README.md
│   │   ├── examples/
│   │   │   ├── minimal/              smallest working call
│   │   │   └── complete/             every feature enabled
│   │   └── tests/
│   │       ├── unit_validation.tftest.hcl
│   │       └── integration_mock.tftest.hcl
│   └── azure-observability/
│       ├── main.tf  variables.tf  outputs.tf  versions.tf
│       ├── README.md
│       ├── examples/basic/
│       └── tests/
│
├── environments/                     composition only, owns state and providers
│   └── dev/
│       ├── providers.tf  backend.tf  main.tf  variables.tf  outputs.tf
│       ├── backend.hcl.example  terraform.tfvars.example
│       └── README.md
│
├── policies/                         conftest policies, each with rego unit tests
│   ├── network/  tagging/  storage/
│   └── README.md
│
├── scripts/bootstrap/                one time state and OIDC setup
├── docs/                             architecture, control mapping, runbooks
└── .github/                          workflows, CODEOWNERS, templates, dependabot
```

Every module owns its own examples and tests. Nothing about a module lives outside its directory, so a module can be extracted into its own repository or published to a registry without touching anything else.

## Modules

| Module | Purpose | Docs |
|---|---|---|
| `azure-observability` | Log Analytics workspace and hardened flow log storage. Deploys first. | [README](modules/azure-observability/README.md) |
| `azure-network` | Resource group, VNet, subnets, per subnet NSG, flow logs, diagnostics. | [README](modules/azure-network/README.md) |

## Try it without an Azure account

```bash
cd modules/azure-network
terraform init -backend=false
terraform validate
terraform test          # mock_provider, full apply path, no cloud

cd ../../
opa test policies -v    # policy unit tests
```

## Deploy for real

```bash
export SUBSCRIPTION_ID=<id> STATE_SA=sttfstate<unique> GITHUB_ORG=skybit9
./scripts/bootstrap/bootstrap.sh

cd environments/dev
cp backend.hcl.example backend.hcl
cp terraform.tfvars.example terraform.tfvars
terraform init -backend-config=backend.hcl
terraform plan
```

Set the repository variable `AZURE_ENABLED` to `true` to switch on the plan and apply jobs. Until then those jobs skip and the pipeline stays green.

## Pipeline

```
lint ─────────┐
module matrix ├──> plan (policy gate) ──> apply (main, approval required)
scan ─────────┤
policy-test ──┘
```

The first four jobs need no credentials. The last two are gated on `AZURE_ENABLED`.

A weekly `drift-detection` workflow runs `terraform plan -detailed-exitcode` and opens a labelled issue when reality diverges from code. See [the runbook](docs/runbook-drift.md).

## Guardrails that fail the build

| Layer | Enforces |
|---|---|
| Variable validation | No Internet sourced inbound, no ports 22 or 3389, retention floor of 90 days, mandatory tags with a valid data classification |
| Terraform tests | NSG per subnet, association coverage, explicit deny rules present, diagnostics on every NSG, bad inputs rejected |
| Conftest policies | Whole plan checks for open NSG rules, missing tags, weak TLS, public blobs, short retention |
| Checkov and Trivy | HIGH and CRITICAL misconfigurations |
| Gitleaks | Secrets anywhere in history |
| tflint | Provider specific correctness |

See the full [control mapping](docs/control-mapping.md).

## Cost

The dev configuration targets a free tier or pay as you go subscription. DDoS Network Protection is off by default because of its fixed monthly cost. Traffic analytics bills on ingestion, so set `enable_traffic_analytics = false` for scratch builds. Run `terraform destroy` after verification.

## Roadmap

1. `azure-observability`, done
2. `azure-network`, done
3. `azure-keyvault`, RBAC mode, purge protection, private endpoint
4. `azure-storage`, private endpoint, customer managed key option
5. `azure-policy`, management group scoped assignments in the EPAC pattern
6. `azure-aks`, CNI Overlay, workload identity, Pod Security Standards
