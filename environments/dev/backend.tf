# Remote state in Azure Storage. Blob lease provides state locking.
# Values are supplied at init time by envs/dev/backend.hcl, which is gitignored.
# terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {
    use_azuread_auth = true
  }
}
