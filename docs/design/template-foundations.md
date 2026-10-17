# Template foundations

Status: working design note

Last reviewed: 2026-09-04

## Purpose

This document records the architecture behind this Copier template. It describes the
patterns selected for a fresh infrastructure repository, the alternatives deliberately
left out, and the points where the repository may grow later.

The template is primarily a deterministic starting point for `infra-copilot`. It must be
safe to publish, contain no deployment identity or credentials, validate without remote
access, and become operational only after a human supplies the public identifiers and
credentials for a real environment.

## Architectural models considered

Three common infrastructure-repository shapes informed the design.

### Small provider-separated repository

The smallest useful model gives each provider or concern an independent Terraform root,
state boundary, credential set, and remote workspace. It is easy to understand and keeps
an operation against one provider from affecting another provider's state.

This is the template's baseline because it provides clear blast-radius boundaries without
introducing modules or orchestration machinery before either is needed.

### Expanded brownfield cloud estate

A larger model retains provider-separated roots while adding an application cloud,
workload identity, declarative imports, deletion protection, and narrowly scoped IAM.
These are strong patterns for adopting valuable existing resources, but their correct
form depends on the resources discovered in the target environment.

The template treats them as opt-in growth patterns. Generic deletion guards, IAM roles,
or generated resource snapshots would suggest protections that may be wrong for a new
organization.

### Mature modular production estate

A long-lived model often uses one composition root with local modules for repeated
production and test deployments. It may integrate multiple network, storage, security,
email, and delivery providers.

That model works when repetition has produced stable module interfaces. Starting a new
repository with empty modules or a single state spanning unrelated providers would add
coupling without providing reuse, so module extraction is deferred until concrete call
sites justify it.

## Selected baseline

The sections below describe the HCP Terraform route. With `backend: object-storage` the
roots are identical except for `backend.tf`, state lives under one prefix per root, and
infra-copilot adds GitHub Actions plan and apply workflows that run applies from `main` in
a `production` environment instead of HCP's confirmation gate.

### State and directory boundaries

The repository starts with two independent roots:

| Terraform root | HCP workspace | Responsibility |
|---|---|---|
| `terraform/cloudflare` | `cloudflare` | Cloudflare zone and related edge resources |
| `terraform/github` | `github-org` | Organization repositories and governance |

Each root owns its provider declaration, input variables, provider lockfile, plan, and
state. HCP Terraform uses the matching directory as its VCS working directory and watches
that directory plus the shared `.infra-copilot/config.md`. Remote execution and manual
apply confirmation are required.

An additional provider receives a new root and workspace only when the deployment
actually uses it. A provider is not pre-created merely because it is a likely future
choice.

### Initial Terraform behavior

The initial configurations use read-only data sources. Their first remote plans prove
that the scoped Cloudflare token and GitHub App can access the identifiers declared in
the repository without creating, updating, or deleting infrastructure.

Managed resources are added after setup. Existing resources must be adopted with
declarative `import` blocks before an apply. Generated import output is review material,
not authoritative configuration: resource names, attributes, and lifecycle rules must be
normalized before commit.

### Configuration ownership

`.infra-copilot/config.md` is the canonical home for public deployment identifiers. It is
not hand-written: `copier.yml` asks for the identifiers, validates their shape, and renders
the config, `.copier-answers.yml`, and each root's `backend.tf`: the literal HCP
organization Terraform's `cloud` block requires, or a `gcs`, `s3` or `azurerm` block with a
per-root state prefix. See `docs/adr/0001-offer-object-storage-and-hcp-backends.md`. Because placeholders never reach a rendered
repository, the contract validator can reject any remaining `replace-with-` value.

Changing an identifier means re-running `copier update` or `copier recopy`, so the config
and the Terraform literals cannot drift. The validator still checks that they agree.

Durable decisions live in `.infra-copilot/decisions.md`. Credentials never belong in
either document. API tokens and GitHub App credentials exist only as sensitive variables
in the relevant HCP workspace.

### Toolchain and provider selection

The repository pins Terraform, GitHub CLI, and jq to exact versions in `mise.toml` and
commits a cross-platform `mise.lock`. Each Terraform root requires the same exact
Terraform version, and HCP workspaces must be configured to match it.

Provider constraints permit compatible patch upgrades within the selected minor line,
while each root's `.terraform.lock.hcl` records the reviewed resolution and checksums.
Provider upgrades are deliberate changes: update the constraint if necessary, refresh
the lockfile, inspect the resulting plan, and verify both roots.

### CI and trust boundaries

GitHub Actions is intentionally credential-free. Pull requests, including those from
forks, can run:

- the template contract validator;
- recursive Terraform formatting checks;
- `terraform init -backend=false` and `terraform validate` for each root.

Actions are pinned to immutable commit identifiers. HCP Terraform owns plans, state, and
provider credentials. Fork-originated remote plans require explicit maintainer approval,
and every apply requires human confirmation after the final plan is read.

This split lets untrusted contributions receive useful static feedback without exposing
the credentials that Terraform code could otherwise read or exfiltrate during planning.

## Required safeguards

Every repository rendered from this template must preserve these invariants:

1. No plaintext credentials, local state, plan files, private keys, or `.tfvars` files are
   committed.
2. Cloudflare and GitHub remain separate state and credential boundaries.
3. Repository, CI, and HCP Terraform versions remain identical.
4. GitHub App authentication is used instead of a credential tied to an individual user.
5. GitHub Actions does not plan or apply against real infrastructure.
6. Forked Terraform receives remote credentials only after maintainer review.
7. Applies remain manual.
8. A plan proposing creation of a resource known to exist is never applied; the resource
   is imported first.

## Deferred capabilities

The following are valuable only when a deployment establishes a real need:

- application-cloud roots and workload identity federation;
- import tooling used during a bounded brownfield migration;
- resource-specific `prevent_destroy` and provider deletion protection;
- shared modules backed by repeated call sites;
- organization-specific branch protection, reviewers, bypass policy, and status names;
- provider-specific WAF, logging, DNSSEC, retention, and recovery controls;
- operational limits, rollback guides, and ownership maps for deployed services.

These capabilities should be added through discovery and recorded in the decisions file.
They must not be copied as generic empty structures or populated with example estate.

## Explicit exclusions

The baseline intentionally excludes:

- a monolithic state spanning unrelated providers;
- empty provider directories and speculative modules;
- organization names, domains, resource identifiers, repository names, or bypass users;
- personal access tokens and locally stored plaintext secrets;
- automated applies and credential-bearing GitHub Actions jobs;
- mutable action tags, tool ranges, and `latest` version selectors;
- copied production resources or generated inventory.

This boundary gives `infra-copilot` a predictable substrate while keeping each generated
repository honest about the infrastructure it actually owns.
