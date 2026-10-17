# Repository instructions

This is a Copier template for a Terraform-managed Cloudflare and GitHub infrastructure
repository. The files rendered into a repository live under `template/`; `copier.yml`
holds the questions. Only `*.jinja` files are templated; everything else is copied
verbatim, so keep the template owner-agnostic and free of deployment identifiers.

The rendered repository is operated with
[infra-copilot](https://github.com/hasansezertasan/infra-copilot), so it must satisfy
that tool's contract: `.infra-copilot/config.md` with an explicit `backend:`, and
`mise.toml` and `mise.lock` at the repository root. Check infra-copilot's references
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
