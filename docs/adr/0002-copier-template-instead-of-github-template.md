# Copier Template Instead of a GitHub Template

## Context and Problem Statement

The project began as `infra-template`, a GitHub template repository. Identifiers
(HCP organization, Cloudflare IDs, managed repositories) had to be written by hand
into several files and synchronised with a script, and a repo created from a GitHub
template has no link back to the template, so later improvements never arrive.

## Considered Options

* Keep the GitHub template and the sync script
* Convert to a Copier template

## Decision Outcome

Chosen option: "Convert to a Copier template", named `copier-infra` like the sibling
`copier-*` templates. Copier asks for the identifiers once, validates them, renders
`config.md` and the Terraform backend blocks, and records the answers and the
template version in `.copier-answers.yml`, so `copier update` walks later tags.
The project files live under `template/`, and the repository root holds the
template's own README, CI, release-please setup and tests.

### Consequences

* Good, because identifiers are asked once and rendered consistently.
* Good, because consumers receive template changes through `copier update`.
* Bad, because repos created from the old GitHub template cannot `copier update`;
  they adopt with `copier copy` and reconcile the result.
