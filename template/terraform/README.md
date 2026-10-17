# Terraform roots

Every child directory is an independent root module and HCP Terraform workspace. This
keeps state, credentials, plans, and failure domains separate.

Each root contains:

- `versions.tf` for the exact Terraform version, provider constraint, and HCP binding;
- `providers.tf` for authentication wiring;
- `variables.tf` for HCP-supplied inputs;
- `main.tf` for the smallest useful baseline;
- `.terraform.lock.hcl` for reproducible provider selection.

Add files by resource category as the estate grows. Do not introduce shared modules until
real repetition produces a stable interface.
