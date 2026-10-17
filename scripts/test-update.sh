#!/usr/bin/env bash
# Render the template at one version, change the template in a new version, run
# `copier update`, and check that consumers keep their answers and local edits.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
work=$(cd "$(mktemp -d)" && pwd -P)
trap 'rm -rf -- "$work"' EXIT

src="$work/src"
dst="$work/dst"
mkdir "$src" "$dst"

git_in() { git -C "$1" -c user.name=test -c user.email=test@example.com "${@:2}"; }

# Snapshot the working tree as a two-version template repository.
(cd "$root" && git ls-files -z --cached --others --exclude-standard | tar --null -T - -cf -) | tar -xf - -C "$src"
git init -q "$src"
git_in "$src" add -A
git_in "$src" commit -q -m "feat: initial"
git_in "$src" tag v1.0.0

copier copy --trust --defaults \
  --data hcp_org=example-org \
  --data github_org=example-org \
  --data apex_domain=example.com \
  --data cloudflare_account_id=0123456789abcdef0123456789abcdef \
  --data cloudflare_zone_id=fedcba9876543210fedcba9876543210 \
  "$src" "$dst" >/dev/null
git init -q "$dst"
git_in "$dst" add -A
git_in "$dst" commit -q -m "chore: initial render"

# Consumer edit that the update must preserve.
printf '| Local choice | kept | locked | Added by the consumer |\n' >> "$dst/.infra-copilot/decisions.md"
git_in "$dst" commit -q -am "docs: record a local decision"

# Template change in v1.0.1.
printf '\nAdded in v1.0.1.\n' >> "$src/template/terraform/README.md"
git_in "$src" commit -q -am "feat: extend the Terraform README"
git_in "$src" tag v1.0.1

copier update --trust --defaults --vcs-ref=v1.0.1 "$dst" >/dev/null

fail() { printf 'update test failed: %s\n' "$1" >&2; exit 1; }

grep -Fq 'Added in v1.0.1.' "$dst/terraform/README.md" || fail "template change not applied"
grep -Fq 'Local choice' "$dst/.infra-copilot/decisions.md" || fail "local edit lost"
grep -Fq '_commit: v1.0.1' "$dst/.copier-answers.yml" || fail "answers file not advanced to v1.0.1"
grep -Fq 'hcp_org: example-org' "$dst/.copier-answers.yml" || fail "answers lost"
if grep -rq '^<<<<<<<' "$dst" --exclude-dir=.git; then fail "merge conflict markers"; fi

git_in "$dst" add -A
(cd "$dst" && ./scripts/validate-template.sh)
printf 'copier update keeps answers and local edits\n'
