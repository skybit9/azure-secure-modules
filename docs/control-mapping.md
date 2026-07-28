# Control mapping

Control intent mapped to the code that satisfies it. Framework references are indicative, not a certification claim. Use this as the starting point for an evidence request, not as the evidence itself.

| Control intent | Common reference | Implementation | Evidence artifact |
|---|---|---|---|
| Network segmentation between tiers | CIS Azure 6.x, SOC2 CC6.1 | One NSG per subnet, association enforced in code | NSG export, `terraform test` assertion on association count |
| Deny by default inbound | CIS Azure 6.x, SOC2 CC6.6 | Explicit deny rule at priority 4096 | NSG rule export |
| No public management access | CIS Azure 6.1, 6.2 | Variable validation rejects 22 and 3389, and any Internet sourced inbound | Failed plan output, Conftest deny message |
| Egress restriction | SOC2 CC6.6 | Explicit deny to Internet outbound, allow scoped to service tags | NSG rule export |
| Audit logging enabled | SOC2 CC7.2, PCI DSS 10.x | Diagnostic settings on VNet, every NSG and the blob service | Diagnostic settings export |
| Network traffic records retained | PCI DSS 10.5.x | Flow logs version 2, floor of 90 days enforced in validation | Flow log configuration, storage contents |
| Encryption in transit | PCI DSS 4.x, CIS Azure 3.x | TLS 1.2 floor on storage, HTTPS only | Storage account properties |
| No anonymous data access | CIS Azure 3.x | Public blob access disabled, shared key auth disabled | Storage account properties |
| Data classification recorded | SOC2 CC3.2 | Mandatory tag validated against an allowed value set | Tag export, failed plan on omission |
| Change management | SOC2 CC8.1 | Protected branch, pull request required, CODEOWNERS review, policy gate on plan | Pull request history, workflow run logs |
| Segregation of duties on deploy | SOC2 CC8.1 | Apply runs only from main behind a protected environment approval | Environment approval records |
| Credential hygiene | SOC2 CC6.1 | OIDC federation, no client secret exists | Federated credential configuration, absence of secrets |
| State integrity and confidentiality | SOC2 CC6.1 | Remote state, shared key auth disabled, versioning, 30 day soft delete | Storage account properties |
| Configuration drift detection | SOC2 CC7.1 | Weekly scheduled plan with detailed exit code, opens an issue on drift | Workflow run history, drift issues |
| Vulnerability and misconfiguration scanning | SOC2 CC7.1 | Checkov and Trivy on every pull request, HIGH and CRITICAL fail | SARIF results in the Security tab |
| Secret leakage detection | SOC2 CC6.1 | Gitleaks on full history | Workflow run logs |

## Gaps deliberately left open

- No customer managed keys yet. Platform managed keys only.
- No private endpoint on the flow log storage account, because flow logs require service access. Tighten with a service endpoint policy once a network exists to attach it to.
- Contributor at subscription scope for the CI identity. Acceptable for dev, replace with a purpose built custom role before production.
