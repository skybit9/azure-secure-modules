# Bootstrap

One time setup that must exist before any pipeline can run. Everything here is deliberately outside the Terraform state that it stores.

Run `./bootstrap.sh` once per subscription. It is idempotent.

Creates:

1. Resource group and storage account for remote state, TLS 1.2 only, no public blob, versioning on, shared key auth disabled so access goes through Entra ID.
2. Entra ID app registration plus service principal for GitHub Actions.
3. Federated credentials for OIDC, so no client secret ever exists.
4. Role assignments scoped to the subscription: Contributor for resource creation, Storage Blob Data Contributor on the state container.

After it finishes, copy the printed client ID, tenant ID and subscription ID into GitHub repository secrets.
