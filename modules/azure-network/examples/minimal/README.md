# Example: minimal

Smallest working call of the `azure-network` module. One subnet, no flow logs, no DDoS plan.

Use this to check the module plans cleanly. Not a compliant configuration on its own, because flow logs are off.

```bash
terraform init
terraform plan -var-file=terraform.tfvars.example
```
