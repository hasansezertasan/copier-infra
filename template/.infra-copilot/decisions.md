# Infrastructure decisions

Durable provider, authentication, state, and safety choices for this repository.

| Decision | Choice | Status | Rationale |
|---|---|---|---|
| Terraform backend | HCP Terraform | locked | Managed remote state, locking, and VCS-driven plans |
| State boundaries | One HCP workspace per provider leaf | locked | Limits credentials and blast radius by concern |
| Toolchain | Exact pins in `mise.toml` and committed `mise.lock` | locked | Keeps local, CI, and HCP Terraform versions aligned |
| GitHub authentication | GitHub App | locked | Avoids credentials tied to an individual user |
| Secret storage | Sensitive HCP workspace variables only | locked | Keeps plaintext credentials out of Git and GitHub Actions |
| Apply policy | Manual confirmation in HCP | locked | Preserves a human review gate for infrastructure changes |

Statuses are `proposed`, `locked`, or `superseded`. Record changed decisions here rather
than silently replacing their history. Never add tokens, private keys, or credentials.
