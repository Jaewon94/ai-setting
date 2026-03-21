## Infra/IaC Rules
- All infrastructure changes are managed as code -- manual console operations forbidden
- Always run plan/dry-run first, review, then apply
- State files (tfstate, etc.) are stored in remote backend; never commit locally
- Secrets use vault/secrets manager -- no plaintext in code or state files
- Separate per-environment (dev/staging/prod) configuration -- variable files or workspaces
- Resource naming follows a consistent convention (environment-service-resource, etc.)
- Drift detection: periodically run plan to check for manual changes
- Testing: plan success verification + module-level tests (terratest, etc.)
