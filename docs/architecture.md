# Architecture

## Layering

```
environments/            composition only, owns state and providers
        |
        v
modules/                 reusable, provider agnostic of environment
        |
        v
policies/                enforced against the plan produced by the layers above
```

Rules that keep the layers honest:

- Modules never declare a `provider` block or a `backend` block. Callers own both.
- Modules never hardcode a region, subscription, name or CIDR.
- Environments never declare a `resource` directly. If a resource is needed, it belongs in a module.
- Each environment and each layer gets its own state key. No workspaces.

## Network topology produced by the complete example

```
vnet 10.90.0.0/16
 |
 |-- snet gateway 10.90.1.0/24   nsg: allow GatewayManager 65200-65535 in
 |                                    deny all in 4096, deny Internet out 4095
 |
 |-- snet app     10.90.2.0/24   nsg: allow 443 in from gateway subnet
 |                                    allow 443 out to AzureCloud tag
 |                                    deny all in 4096, deny Internet out 4095
 |
 |-- snet data    10.90.3.0/24   nsg: no allow rules at all
                                      reachable only via private endpoint
```

Every NSG has a diagnostic setting and a version 2 flow log. Both land in the Log Analytics workspace created by `azure-observability`.

## Deployment order

1. `azure-observability`, because everything else needs the workspace ID
2. `azure-network`
3. Future modules: key vault, storage, policy assignments, AKS

## Design decisions worth defending in review

**One NSG per subnet, not one shared NSG.** A shared NSG makes blast radius unprovable and forces rule priorities to encode subnet identity.

**Explicit deny rules at 4095 and 4096.** Azure already has an implicit deny. The explicit rule exists so the deny is visible in an export and can be pointed at during an audit walkthrough.

**Validation in variables, not documentation.** A guardrail written in a README is a suggestion. A guardrail in a `validation` block fails the plan.

**Flow log retention floored at 90 days in code.** Retention is the single most common gap found in a first audit, and the cheapest to fix before deployment rather than after.
