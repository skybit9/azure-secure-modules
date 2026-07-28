# Contributing

## Branching

`main` is protected. All changes arrive by pull request reviewed by a CODEOWNER. No direct pushes.

## Before opening a pull request

```bash
pre-commit run --all-files
terraform fmt -recursive

# for every module you touched
cd modules/<module>
terraform init -backend=false && terraform validate && terraform test

# if you touched policies
opa test policies -v
```

## Module contract

A module directory is self contained. It must have:

```
modules/<name>/
├── versions.tf        provider constraints, no provider block
├── variables.tf       description on every input, validation on security relevant ones
├── main.tf            resources, split by concern once past roughly 150 lines
├── outputs.tf         description on every output
├── README.md          purpose, guardrail table, usage
├── examples/
│   └── <name>/        runnable, with its own versions.tf and terraform.tfvars.example
└── tests/
    ├── unit_validation.tftest.hcl
    └── integration_mock.tftest.hcl
```

Hard rules:

- No `provider` block and no `backend` block inside a module. Callers own both.
- No hardcoded region, subscription ID, resource name or CIDR.
- Every resource that supports diagnostic settings gets one.
- Every new module is added to the matrix in `.github/workflows/terraform-ci.yml`.

## Environment contract

`environments/<env>` composes modules and owns state and providers. It declares no resources directly. If you need a resource, it goes in a module.

## Adding a guardrail

Prefer variable validation, because it fails fastest and needs no plan. If the rule needs whole plan context, add a Conftest policy under `policies/` with a matching `_test.rego` covering one failing case and one passing case. Policies without tests are not accepted.
