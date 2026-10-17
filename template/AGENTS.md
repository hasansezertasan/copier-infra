# Agent instructions

This repository is the consuming infrastructure repository for `infra-copilot`.

## Workflow

- Use infra-copilot for setup, import, provider/resource additions, and status checks.
- Read `.infra-copilot/config.md` before acting. It is rendered by copier from
  `.copier-answers.yml`, which also writes the literal HCP organization into both
  Terraform `cloud` blocks. Change those values with `copier update` or `copier recopy`,
  never by hand, and commit the answers file, config, and Terraform roots together.
- Record durable architecture, authentication, state, and safety choices in
  `.infra-copilot/decisions.md`.
- Keep Cloudflare and GitHub in separate Terraform roots and HCP workspaces.
- Run `mise exec -- make check` before proposing a change.

## Safety

- Never read, print, request, or commit plaintext credentials.
- Keep secrets in sensitive HCP Terraform workspace variables.
- Never apply when a plan proposes creating a resource that already exists; import it.
- Never automate applies. A human confirms the reviewed plan in HCP Terraform.
- Treat forked pull-request Terraform as untrusted code. GitHub Actions must remain
  credential-free; HCP plans for forks require explicit maintainer approval.

## Terraform conventions

- Each `terraform/*` directory is an independent root with its own lock file and state.
- Pin Terraform in `mise.toml`, require that exact version in each root, and configure
  every HCP workspace to use the same version.
- Commit `.terraform.lock.hcl` files. Upgrade providers deliberately.
- Prefer clear resource-category files over a growing `main.tf`.
- Extract a module only after repeated use reveals a stable abstraction.
- Use declarative `import` blocks for existing resources.
