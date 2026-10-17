# Contributing to copier-infra

## Commits and pull requests

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/): `<type>[(scope)][!]: <description>`.
- Pull request titles use the same format, because the repository squash-merges with the PR title and release-please builds the changelog and picks the next version from it.
- `feat` bumps the minor version, `fix` the patch. A `!` or a `BREAKING CHANGE:` footer marks a breaking change. Before 1.0, a breaking change or a `feat` bumps the minor version.
- Branch names are `<type>/<description>`, lowercase and hyphenated (`feature`, `bugfix`, `hotfix`, `release`, `chore`).

## Testing

```sh
mise trust template/mise.toml
mise -C template install terraform
mise -C template exec -- "$PWD/scripts/test-template.sh"
node --test "tests/*.test.mjs"
```

## Release flow

`version.txt` and `.release-please-manifest.json` carry the version; release-please bumps both. The first release is 0.1.0.

1. On `main`, the `release` workflow runs the same `CI` workflow as pull requests, then `scripts/release-merge.mjs`, which allows a release only for the one pending release PR merged as the commit being released.
2. release-please opens or updates a release PR with the version bump and changelog.
3. Review it and merge it once its checks pass.
4. The next `release` run creates the `vX.Y.Z` tag and GitHub Release. Consumers' `copier update` resolves against that tag.

If validation of a release merge fails transiently, rerun that merge's failed workflow. A new green push does not authorize releasing the older pending merge.

## One-time repository setup

None of these settings can be read from the repository, so CI cannot catch a missing one.

- [ ] **Allow Actions to open pull requests.** Settings → Actions → General → Workflow permissions → "Allow GitHub Actions to create and approve pull requests".
- [ ] **Squash merge only**, with the PR title as the commit title, and delete branches on merge.
- [ ] **Protect `main`.** Require a pull request and require the `render and validate template` status check.
- [ ] **Close and reopen the release PR before merging it.** release-please runs on the implicit `GITHUB_TOKEN`, so the release PR reports no required checks until you close and reopen it. Reopen again after each update, or run `gh workflow run ci.yml --ref release-please--branches--main`.
