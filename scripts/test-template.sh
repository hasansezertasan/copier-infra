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

# An identifier outside the README's Config block must be caught.
leak="$work/leak"
copier copy --trust --defaults "${common[@]}" --data backend=hcp --data hcp_org=example-org \
  "$root" "$leak" >/dev/null
(
  cd "$leak"
  git init -q
  printf '\nLeaked 0123456789abcdef0123456789abcdef here.\n' >> README.md
  git add -A
  if ./scripts/validate-template.sh >/dev/null 2>&1; then
    printf 'validator missed an identifier outside the Config block\n' >&2
    exit 1
  fi
)

# The rejection paths must reject.
rejects() {
  local label=$1
  shift
  if copier copy --trust --defaults "${common[@]}" --data backend=object-storage "$@" \
    "$root" "$work/bad-$label" >/dev/null 2>&1; then
    printf 'accepted an invalid answer: %s\n' "$label" >&2
    exit 1
  fi
}
rejects gcs-uppercase --data state_backend=gcs --data state_bucket=Bad_Bucket
rejects gcs-short --data state_backend=gcs --data state_bucket=ab
rejects gcs-trailing-hyphen --data state_backend=gcs --data state_bucket=state-
rejects s3-underscore --data state_backend=s3 --data state_bucket=foo_bar \
  --data state_region=us-east-1 --data state_lock_table=locks
rejects s3-long --data state_backend=s3 --data "state_bucket=$(printf 'a%.0s' {1..64})" \
  --data state_region=us-east-1 --data state_lock_table=locks
rejects azure-double-hyphen --data state_backend=azurerm --data state_bucket=a--b \
  --data azure_storage_account=examplestate --data azure_resource_group=rg --data state_region=westeurope
rejects azure-underscore --data state_backend=azurerm --data state_bucket=tf_state \
  --data azure_storage_account=examplestate --data azure_resource_group=rg --data state_region=westeurope

printf 'rendered templates are valid\n'
