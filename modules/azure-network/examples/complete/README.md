# Example: complete

Every feature of the `azure-network` module turned on: three tiered subnets, scoped allow rules, service endpoints, NSG flow logs with traffic analytics, and full diagnostics.

This is the configuration the control mapping in the root README describes. It stands up its own observability stack, so it runs standalone.

```bash
terraform init
cp terraform.tfvars.example terraform.tfvars   # then edit
terraform plan
```

Cost warning: traffic analytics bills on ingestion. Destroy after verifying.
