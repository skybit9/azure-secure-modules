# Security

## Reporting

Open a private security advisory on this repository. Do not open a public issue for a suspected vulnerability.

## Secrets

No secrets belong in this repository. Deployment authentication uses GitHub OIDC federation to Entra ID, so no client secret or certificate exists to leak. Gitleaks runs on every push and on full history.

Files matching `*.tfvars` and `backend.hcl` are gitignored. Only the `.example` variants are tracked.

## Least privilege

The CI service principal holds Contributor at subscription scope for the dev environment only. Production scope should be narrowed to purpose built custom roles before any production use.

## State

Terraform state can contain sensitive values. State lives in Azure Storage with shared key auth disabled, TLS 1.2 enforced, blob versioning and 30 day soft delete enabled, and access granted only through Entra ID role assignments.
