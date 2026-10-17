#!/usr/bin/env bash
# Render the template with fixed answers and run the rendered project's own checks.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
out=$(mktemp -d)
trap 'rm -rf -- "$out"' EXIT

copier copy --trust --defaults \
  --data hcp_org=example-org \
  --data github_org=example-org \
  --data apex_domain=example.com \
  --data cloudflare_account_id=0123456789abcdef0123456789abcdef \
  --data cloudflare_zone_id=fedcba9876543210fedcba9876543210 \
  "$root" "$out"

cd "$out"
git init -q
git add -A
./scripts/validate-template.sh
terraform fmt -check -recursive terraform
printf 'rendered template is valid\n'
