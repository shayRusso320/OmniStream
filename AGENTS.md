# AGENTS.md — OmniStream Terraform Infrastructure

## Project Overview

This is the Terraform infrastructure repo for **OmniStream**, an AWS-based project.
It provisions and manages all cloud resources including Cognito (auth), Lambda functions, S3, DynamoDB, and integrations with external services (OpenAI, Qdrant).

- **Cloud Provider**: AWS (`eu-north-1` by default)
- **Terraform Version**: >= 1.5.0
- **AWS Provider Version**: 6.33.0 (pinned — do not upgrade without testing)
- **State Backend**: S3 (`omnistream-tf-state`) with DynamoDB locking (`dynamo-tf-locks`)

---

## File Structure

```
.
├── backend.tf          # Remote state configuration (S3 + DynamoDB lock)
├── versions.tf         # Terraform and provider version constraints
├── providers.tf        # Provider configuration
├── variables.tf        # All input variable declarations
├── terraform.tfvars    # Variable values (never commit secrets here)
├── outputs.tf          # Output values
├── infra.tf            # Core infrastructure resources
├── flows.tf            # Workflow / event-driven resources
└── flows/              # Supporting files for flows (e.g. templates, policies)
    infra/              # Supporting files for infra (e.g. IAM policies, scripts)
```

---

## Coding Conventions

### Naming
- All resource names must be prefixed with `omnistream-` (e.g. `omnistream-api-lambda`, `omnistream-user-pool`)
- Use **kebab-case** for resource names and **snake_case** for Terraform identifiers (locals, variables, outputs)
- Be descriptive: prefer `omnistream-auth-user-pool` over `omnistream-up`

### Variables
- Every `variable` block **must** have a `description`
- Every `variable` block **must** have an explicit `type`
- Mark sensitive variables with `sensitive = true` (credentials, API keys, secrets)
- Never hardcode values that belong in `variables.tf` or `terraform.tfvars`
- Never commit actual secret values — use placeholder comments or a secrets manager reference

### Resources
- Every resource **must** include the common `tags` variable: `tags = var.tags`
- Add resource-specific tags inline alongside `tags = var.tags` using `merge()` if needed:
  ```hcl
  tags = merge(var.tags, { Name = "omnistream-my-resource" })
  ```
- Use `locals` for any repeated expressions or computed values
- Prefer **data sources** over hardcoding existing resource IDs

### Outputs
- Every significant resource should have a corresponding output in `outputs.tf`
- All `output` blocks must have a `description`
- Mark sensitive outputs with `sensitive = true`

### Formatting & Style
- Always run `terraform fmt` before committing — all code must be properly formatted
- Use section comment headers (e.g. `################### COGNITO ###################`) to group related resources within a file, consistent with the existing style
- Keep files focused: don't add unrelated resources to an existing `.tf` file; create a new one if needed

---

## Security Rules

- **Never** hardcode AWS credentials, API keys, or secrets in any `.tf` or `.tfvars` file
- Sensitive variables (`google_client_secret`, `openai_api_key`, `qdrant_api_key`, etc.) must always be passed via environment variables or a secrets manager — never via plaintext `terraform.tfvars` in version control
- S3 state bucket must always have `encrypt = true` (already set — do not remove)
- IAM policies must follow **least privilege** — never use `"*"` for actions or resources unless absolutely required and explicitly justified in a comment
- Enable versioning and access logging on all S3 buckets you create

---

## Workflow

### Common Commands
```bash
# Initialize (after cloning or adding a new provider/module)
terraform init

# Preview changes before applying
terraform plan

# Apply changes
terraform apply

# Format all files
terraform fmt -recursive

# Validate configuration
terraform validate

# Destroy (use with extreme caution)
terraform destroy
```

### Before Every PR / Commit
1. Run `terraform fmt -recursive` and commit any formatting changes
2. Run `terraform validate` — it must pass with no errors
3. Run `terraform plan` and review the diff carefully before applying
4. Ensure no sensitive values are present in the diff or in committed files

---

## General Rules for AI Agents

- **Do not** change `backend.tf` or `versions.tf` without an explicit instruction to do so
- **Do not** upgrade pinned provider versions (`versions.tf`) unless explicitly asked
- **Do not** remove or modify the `tags` variable or existing tag defaults
- **Do not** apply (`terraform apply`) autonomously — always stop at `plan` and present the output
- When adding a new resource, always check if a variable already exists in `variables.tf` before creating a new one
- When unsure about a naming convention, look at existing resources in `infra.tf` and follow the same pattern
- Prefer modifying existing `.tf` files over creating new ones, unless the new resource is clearly a separate concern
