# Render the Config block and Decisions table as README sections

## Context and Problem Statement

The Template rendered `.infra-copilot/config.md` and `.infra-copilot/decisions.md`. A
directory named after the product makes any rename a breaking contract change across the
Template and infra-skills, and the checks need a Template-owned, parseable home for the
locked decisions. infra-skills ADR 0002 moves both documents into the root `README.md`.

## Considered Options

* Keep rendering `.infra-copilot/config.md` and `decisions.md`: rejected, see infra-skills
  ADR 0002.
* Put every Config field outside the markers and let `copier update` own the block:
  rejected, because it would erase the attestations infra-skills writes.
* Keep `hcp_status_check_id` as a Copier question: rejected, because the Skills write it.

## Decision Outcome

The rendered `README.md` carries two fixed sections, and `.infra-copilot/` is no longer
rendered.

- `## Config` holds one fenced `yaml` block between `<!-- infra:config start -->` and
  `<!-- infra:config end -->`. It keeps the previous config schema.
- Inside the block, `# infra:customization start` and `# infra:customization end` enclose
  the fields infra-skills and humans write: `leaf_backends`, `state_transfers`,
  `github_apps`, `additional_providers` and, for `hcp`, `hcp_status_check_id`. The
  attestation timestamps live in those fields. Every Template answer, including
  `backend`, stays outside the markers, so `copier update` owns it.
- `## Decisions` holds a table with the columns Decision, Choice, Status and Rationale
  between `<!-- infra:decisions start -->` and `<!-- infra:decisions end -->`.
- The Terraform roots decode the Config block from `README.md`, and
  `scripts/validate-template.sh` checks that each marker appears exactly once.
- `hcp_status_check_id` is no longer a Copier question, because infra-skills writes it
  after the first VCS connection. A question would leave two writers for one value.

The Template's CI runs no Terraform plan or apply workflow; infra-skills owns those. The
rendered `ci.yml` keeps its credential-free `terraform fmt` and `terraform validate` jobs,
because the Skills' HCP documentation names those status-check contexts as required.

## Consequences

- Existing repos rendered from an earlier commit have no sections; adopting this version
  with `copier update` adds them and deletes `.infra-copilot/`. State-location changes of
  this kind are called out in the README.
- The first release tag is cut by release-please from the squash-merged `feat!` title; it
  becomes the minimum Template version in infra-skills' Template contract.
