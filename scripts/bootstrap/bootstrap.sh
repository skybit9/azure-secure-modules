#!/usr/bin/env bash
# Bootstrap remote state and GitHub OIDC federation for this repo.
# Run once per subscription. Safe to re-run.
set -euo pipefail

# ---- edit these before first run -------------------------------------------
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:?set SUBSCRIPTION_ID}"     # target Azure subscription
LOCATION="${LOCATION:-canadacentral}"                          # region for state storage
STATE_RG="${STATE_RG:-rg-tfstate-shared}"                      # resource group holding state
STATE_SA="${STATE_SA:?set STATE_SA to a globally unique name}" # storage account, 3 to 24 lowercase alphanumeric
STATE_CONTAINER="${STATE_CONTAINER:-tfstate}"                  # blob container name
GITHUB_ORG="${GITHUB_ORG:?set GITHUB_ORG}"                     # GitHub username or org
GITHUB_REPO="${GITHUB_REPO:-azure-secure-modules}"             # repository name
APP_NAME="${APP_NAME:-gha-${GITHUB_REPO}}"                     # Entra ID app registration name
# ----------------------------------------------------------------------------

az account set --subscription "$SUBSCRIPTION_ID"               # pin the working subscription

# State resource group.
az group create --name "$STATE_RG" --location "$LOCATION" --output none

# State storage account. Shared key auth disabled forces Entra ID auth for state access.
az storage account create \
  --name "$STATE_SA" \
  --resource-group "$STATE_RG" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --https-only true \
  --allow-blob-public-access false \
  --allow-shared-key-access false \
  --output none

# Blob versioning and soft delete protect against a corrupted or deleted state file.
az storage account blob-service-properties update \
  --account-name "$STATE_SA" \
  --resource-group "$STATE_RG" \
  --enable-versioning true \
  --enable-delete-retention true \
  --delete-retention-days 30 \
  --output none

# Container for state blobs, created with the caller's Entra ID identity.
az storage container create \
  --name "$STATE_CONTAINER" \
  --account-name "$STATE_SA" \
  --auth-mode login \
  --output none

# App registration for GitHub Actions.
APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)

# Service principal backing the app registration.
az ad sp create --id "$APP_ID" --output none 2>/dev/null || true
SP_OBJECT_ID=$(az ad sp show --id "$APP_ID" --query id -o tsv)

# Federated credential for pull request runs.
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gha-pull-request\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:pull_request\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" --output none

# Federated credential for the main branch.
az ad app federated-credential create --id "$APP_ID" --parameters "{
  \"name\": \"gha-main-branch\",
  \"issuer\": \"https://token.actions.githubusercontent.com\",
  \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:ref:refs/heads/main\",
  \"audiences\": [\"api://AzureADTokenExchange\"]
}" --output none

# Federated credentials for the protected environments used by the workflows.
for ENV_NAME in dev dev-apply; do
  az ad app federated-credential create --id "$APP_ID" --parameters "{
    \"name\": \"gha-env-${ENV_NAME}\",
    \"issuer\": \"https://token.actions.githubusercontent.com\",
    \"subject\": \"repo:${GITHUB_ORG}/${GITHUB_REPO}:environment:${ENV_NAME}\",
    \"audiences\": [\"api://AzureADTokenExchange\"]
  }" --output none
done

# Subscription scoped Contributor so Terraform can build resources.
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}" \
  --output none

# Data plane access to the state container, required because shared keys are disabled.
az role assignment create \
  --assignee-object-id "$SP_OBJECT_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${STATE_RG}/providers/Microsoft.Storage/storageAccounts/${STATE_SA}" \
  --output none

TENANT_ID=$(az account show --query tenantId -o tsv)

cat <<SUMMARY

Bootstrap complete.

Add these as GitHub repository secrets:
  AZURE_CLIENT_ID        ${APP_ID}
  AZURE_TENANT_ID        ${TENANT_ID}
  AZURE_SUBSCRIPTION_ID  ${SUBSCRIPTION_ID}

Add these as GitHub repository variables:
  TFSTATE_RG             ${STATE_RG}
  TFSTATE_SA             ${STATE_SA}

Local init:
  cd envs/dev
  cp backend.hcl.example backend.hcl
  cp terraform.tfvars.example terraform.tfvars
  terraform init -backend-config=backend.hcl

SUMMARY
