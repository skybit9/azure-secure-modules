# Runbook: drift detected

Triggered by the weekly `drift-detection` workflow opening an issue labelled `drift`.

## 1. Confirm

Open the workflow run and read the plan output. Classify the change:

- **Expected**, someone applied an approved change out of band
- **Unexpected**, a manual portal change, an Azure Policy remediation, or a provider behaviour change
- **Noise**, a provider version bump changing how an attribute is read

## 2. Contain

If the drift removed a control (an NSG rule deleted, a diagnostic setting removed, retention lowered), treat it as a security event before treating it as a Terraform problem. Reapply from code immediately, then investigate who made the change and why the path existed.

## 3. Reconcile

| Case | Action |
|---|---|
| Code is right, cloud is wrong | `terraform apply` from main, no code change |
| Cloud is right, code is stale | Open a pull request updating the code, then apply |
| Attribute is externally managed | Add a targeted `lifecycle { ignore_changes = [...] }` with a comment naming what manages it |
| Resource created outside Terraform | `terraform import` or `aztfexport`, then bring under module control |

Never resolve drift by deleting state or by tainting resources at random. Both hide the cause.

## 4. Close

Comment on the drift issue with the classification, the action taken, and the follow up that prevents recurrence. Close the issue only after the next scheduled run comes back clean.
