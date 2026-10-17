#!/usr/bin/env bash
# Render the template once per backend and run the rendered project's own checks.
set -euo pipefail

root=$(git rev-parse --show-toplevel)
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT

common=(
  --data github_org=example-org
  --data apex_domain=example.com
  --data cloudflare_account_id=0123456789abcdef0123456789abcdef
  --data cloudflare_zone_id=fedcba9876543210fedcba9876543210
)

# name:extra copier answers
cases=(
  "hcp:--data backend=hcp --data hcp_org=example-org"
  "gcs:--data backend=object-storage --data state_backend=gcs --data state_bucket=example-state"
  "s3:--data backend=object-storage --data state_backend=s3 --data state_bucket=example-state --data state_region=us-east-1 --data state_lock_table=example-locks"
  "azurerm:--data backend=object-storage --data state_backend=azurerm --data state_bucket=tfstate --data azure_storage_account=examplestate --data azure_resource_group=example-rg --data state_region=westeurope"
)

for entry in "${cases[@]}"; do
  name=${entry%%:*}
  # shellcheck disable=SC2206
  extra=(${entry#*:})
  out="$work/$name"
  printf '== rendering %s\n' "$name"
  copier copy --trust --defaults "${common[@]}" "${extra[@]}" "$root" "$out" >/dev/null
  (
    cd "$out"
    git init -q
    git add -A
    ./scripts/validate-template.sh
    terraform fmt -check -recursive terraform
    for directory in terraform/cloudflare terraform/github; do
      terraform -chdir="$directory" init -backend=false -input=false -lockfile=readonly >/dev/null
      terraform -chdir="$directory" validate >/dev/null
    done
  )
done

# The rejection paths must reject.
if copier copy --trust --defaults "${common[@]}" --data backend=object-storage \
  --data state_backend=gcs --data state_bucket=Bad_Bucket "$root" "$work/bad" >/dev/null 2>&1; then
  printf 'an invalid state_bucket was accepted\n' >&2
  exit 1
fi

printf 'rendered templates are valid\n'
