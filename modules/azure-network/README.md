# azure-network

Reusable Azure network foundation with a deny by default posture and audit evidence wired in from the first apply.

## What it creates

- Resource group
- Virtual network, optional DDoS Network Protection plan attachment
- Subnets from a map, with optional service endpoints and delegation
- One NSG per subnet, associated to that subnet
- Explicit deny all inbound rule at priority 4096
- Explicit deny internet outbound rule at priority 4095
- Diagnostic settings on the VNet and every NSG, shipped to Log Analytics
- NSG flow logs version 2 with traffic analytics, 90 day minimum retention

## Guardrails enforced in code

| Guardrail | Where |
|---|---|
| No inbound allow rule sourced from Internet, 0.0.0.0/0 or wildcard | variable validation on `subnets` |
| No inbound SSH (22) or RDP (3389) | variable validation on `subnets` |
| Flow log retention 90 days or more | variable validation on `flow_log_retention_days` |
| Mandatory governance tags including data classification | variable validation on `tags` |
| DDoS plan ID required when DDoS is enabled | lifecycle precondition on the VNet |
| Private endpoint network policies enabled by default | subnet default |

## Usage

```hcl
module "network" {
  source = "../../modules/azure-network"

  name_prefix        = "indjt"
  environment        = "dev"
  location           = "canadacentral"
  vnet_address_space = ["10.20.0.0/16"]

  subnets = {
    app = {
      address_prefixes  = ["10.20.1.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.Storage"]
      allow_rules = [{
        name                    = "allow-https-from-appgw"
        priority                = 200
        direction               = "Inbound"
        access                  = "Allow"
        protocol                = "Tcp"
        destination_port_ranges = ["443"]
        source_address_prefix   = "10.20.2.0/24"
      }]
    }
    data = {
      address_prefixes = ["10.20.3.0/24"]
    }
  }

  log_analytics_workspace_id  = module.observability.workspace_id
  network_watcher_name        = "NetworkWatcher_canadacentral"
  flow_log_storage_account_id = module.observability.flow_log_storage_id

  tags = {
    owner               = "indrajeet.shelar"
    cost_center         = "portfolio"
    data_classification = "internal"
    managed_by          = "terraform"
  }
}
```

## Examples

| Example | Purpose |
|---|---|
| `examples/minimal` | Smallest working call, one subnet, flow logs off |
| `examples/complete` | Three tiered subnets, scoped rules, flow logs and traffic analytics on |

## Tests

```bash
terraform init -backend=false
terraform test
```

`tests/unit_validation.tftest.hcl` proves bad inputs are rejected.
`tests/integration_mock.tftest.hcl` runs the full apply path against a mocked provider, so no Azure subscription is needed.

## Notes

- Set `flow_log_storage_account_id` and `network_watcher_name` to null to skip flow logs. Cheaper for scratch builds, but the compliance story goes with it.
- Traffic analytics needs the workspace GUID, not the resource ID. Both are passed separately on purpose.
