# Offer Object-Storage and HCP Backends

## Context and Problem Statement

The template started HCP-only: a `cloud` block, `hcp_org` as a required answer, and
a safety model written around HCP workspaces. infra-skills, the tool this template
exists to feed, supports two backends and recommends object storage with GitHub
Actions. Its HCP route needs a paid tier with team management, even below 500
resources, because of its plan-only team token. A fresh HCP render also lacked the
`backend:` field infra-skills requires, so every action skill stopped at startup.

## Considered Options

* Stay HCP-only and say so
* Ask for the backend and render both routes
* Publish a sibling template for object storage

## Decision Outcome

Chosen option: "Ask for the backend and render both routes", with `object-storage`
as the default to match infra-skills' recommendation. `backend` is the first
question. The HCP answer (`hcp_org`; `hcp_status_check_id` was a second answer until ADR 0003
moved it to the Skills) and the bucket answers
(`state_backend`, `state_bucket`, `state_prefix`, `state_region`, plus the lock table and
Azure fields where they apply) are asked only for the chosen route. `config.md`
follows infra-skills' schema, `backend.tf` renders the `cloud` block or a `gcs`,
`s3` or `azurerm` block with one prefix per root, and `AGENTS.md`, `decisions.md`
and the README state the matching credential and apply rules.

The template does not ship the plan and apply workflows, the state bucket, the
GitHub Apps or the `production` environment. infra-setup creates and
verifies them, and copying them here would drift from the tool that checks them.

### Consequences

* Good, because a render matches the config contract infra-skills enforces.
* Good, because the recommended route is the default and HCP stays available.
* Good, because the validator and `scripts/test-template.sh` check all four
  backends (`hcp`, `gcs`, `s3`, `azurerm`) on every change.
* Bad, because the templated documents now branch on the backend and need care.
* Bad, because switching backend after rendering is a state migration, not a
  `copier update` answer change; infra-skills' runbook owns that migration.
