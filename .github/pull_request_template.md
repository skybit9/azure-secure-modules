## What changed

Short description of the change.

## Why

Link the issue or state the driver.

## Blast radius

- [ ] Module change, affects every consumer
- [ ] Environment change, affects one environment only
- [ ] Policy change, may fail existing pull requests
- [ ] Documentation only

## Checks

- [ ] `terraform fmt -recursive` clean
- [ ] `terraform test` passes for every touched module
- [ ] Plan reviewed, no unexpected destroys
- [ ] New inputs have descriptions and validation where security relevant
- [ ] Module README and examples updated

## Plan output

```
paste the relevant plan excerpt here
```
