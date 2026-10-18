# Repository instructions

This is a Copier template for a Terraform-managed Cloudflare and GitHub infrastructure
repository. The files rendered into a repository live under `template/`; `copier.yml`
holds the questions. Only `*.jinja` files are templated; everything else is copied
verbatim, so keep the template owner-agnostic and free of deployment identifiers.

The rendered repository is operated with
[infra-skills](https://github.com/hasansezertasan/infra-skills), so it must satisfy
that tool's contract: `.infra-copilot/config.md` with an explicit `backend:`, and
`mise.toml` and `mise.lock` at the repository root. Check infra-skills' references
before moving or renaming anything it reads.

Persist decisions as MADR records in `docs/adr/` with sequential four-digit prefixes,
and commit them with the related work.

Before opening a pull request, run the same checks CI runs:

```sh
mise trust template/mise.toml
mise -C template install terraform
mise -C template exec -- "$PWD/scripts/test-template.sh"
./scripts/test-update.sh
node --test "tests/*.test.mjs"
```

Branch names and pull request titles follow Conventional Branch and Conventional
Commits; `release-please` builds the changelog from the squash-merged titles.

## Agent skills

### Issue tracker

Issues live in GitHub Issues on `hasansezertasan/copier-infra`, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-label vocabulary (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
