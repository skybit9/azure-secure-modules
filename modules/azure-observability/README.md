# azure-observability

Central logging foundation. Every other module in this repository ships diagnostics here, so this deploys first.

## What it creates

- Resource group
- Log Analytics workspace, 90 day minimum retention
- Storage account for raw NSG flow logs: TLS 1.2 floor, HTTPS only, shared key auth disabled, public blob access blocked, versioning and 30 day soft delete on
- Diagnostic settings on the blob service so the evidence store logs its own reads, writes and deletes

## Guardrails enforced in code

| Guardrail | Where |
|---|---|
| Retention 90 days or more | variable validation on `log_retention_days` |
| No shared key auth on the evidence store | `shared_access_key_enabled = false` |
| TLS 1.2 floor | `min_tls_version` |
| No anonymous blob access | `allow_nested_items_to_be_public = false` |

## Usage

See `examples/basic`.

## Outputs worth noting

`workspace_id` is the ARM resource ID. `workspace_guid` is the customer ID. Traffic analytics needs the GUID, diagnostic settings need the resource ID, which is why both are exported separately.
