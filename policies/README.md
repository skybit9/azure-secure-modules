# policies

Conftest and OPA policies enforced against the Terraform plan JSON on every pull request. These catch what variable validation cannot, because they see the whole plan rather than a single input.

## Layout

| Directory | Enforces |
|---|---|
| `network/` | No inbound allow from the public internet, no exposed management ports |
| `tagging/` | The four mandatory governance tags on every taggable resource |
| `storage/` | TLS 1.2 floor, no anonymous blob access, 90 day flow log retention |

Each policy has a matching `_test.rego` with both a failing case and a passing case. Policies without tests are not accepted.

## Running locally

```bash
opa test policies -v

cd environments/dev
terraform plan -out=tfplan
terraform show -json tfplan > tfplan.json
conftest test tfplan.json --policy ../../policies
```
