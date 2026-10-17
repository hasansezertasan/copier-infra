#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

required_files=(
  .infra-copilot/config.md
  .copier-answers.yml
  .infra-copilot/decisions.md
  mise.toml
  mise.lock
  terraform/cloudflare/versions.tf
  terraform/cloudflare/providers.tf
  terraform/cloudflare/variables.tf
  terraform/cloudflare/main.tf
  terraform/cloudflare/.terraform.lock.hcl
  terraform/github/versions.tf
  terraform/github/providers.tf
  terraform/github/variables.tf
  terraform/github/main.tf
  terraform/github/.terraform.lock.hcl
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    printf 'missing required file: %s\n' "$path" >&2
    exit 1
  fi
done

config_path=.infra-copilot/config.md

if grep -Fq 'replace-with-' "$config_path"; then
  printf '%s contains unresolved placeholders\n' "$config_path" >&2
  exit 1
fi

config_keys=(
  hcp_org
  github_org
  apex_domain
  cloudflare_account_id
  cloudflare_zone_id
  managed_repos
  hcp_status_check_id
)

for key in "${config_keys[@]}"; do
  if ! grep -Eq "^${key}:" "$config_path"; then
    printf '%s is missing %s\n' "$config_path" "$key" >&2
    exit 1
  fi
done

hcp_org=$(sed -nE 's/^hcp_org:[[:space:]]*"?([^"[:space:]]+)"?[[:space:]]*$/\1/p' "$config_path")
if [[ -z "$hcp_org" ]]; then
  printf '%s must contain one non-empty hcp_org\n' "$config_path" >&2
  exit 1
fi

terraform_pin=$(sed -n 's/^terraform = "\([^"]*\)"$/\1/p' mise.toml)
if [[ -z "$terraform_pin" ]]; then
  printf 'mise.toml must contain an exact Terraform pin\n' >&2
  exit 1
fi

for path in terraform/cloudflare/versions.tf terraform/github/versions.tf; do
  if ! grep -Fq "required_version = \"= $terraform_pin\"" "$path"; then
    printf '%s must require Terraform %s exactly\n' "$path" "$terraform_pin" >&2
    exit 1
  fi
  if ! grep -Fq "organization = \"$hcp_org\"" "$path"; then
    printf '%s must use hcp_org from %s\n' "$path" "$config_path" >&2
    exit 1
  fi
done

if ! grep -Fq 'name = "cloudflare"' terraform/cloudflare/versions.tf; then
  printf 'Cloudflare root must bind to the cloudflare workspace\n' >&2
  exit 1
fi

if ! grep -Fq 'name = "github-org"' terraform/github/versions.tf; then
  printf 'GitHub root must bind to the github-org workspace\n' >&2
  exit 1
fi

for tool in gh jq; do
  if ! grep -Eq "^$tool = \"[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.+-]+)?\"$" mise.toml; then
    printf 'mise.toml must contain an exact %s pin\n' "$tool" >&2
    exit 1
  fi
done

for secret_pattern in \
  '*.pem' '*.key' '*.tfvars' '*.tfvars.json' '*.tfstate' '*.tfstate.*' \
  '*.tfplan' '*.tfplan.*' '.env' '.env.*'; do
  tracked_matches=$(git ls-files -- "$secret_pattern" "**/$secret_pattern" \
    | grep -Ev '(^|/)\.env\.example$' || true)
  if [[ -n "$tracked_matches" ]]; then
    printf 'tracked secret or local-state file matches %s\n' "$secret_pattern" >&2
    exit 1
  fi
done

identity_found=false
while IFS= read -r -d '' path; do
  [[ "$path" == .infra-copilot/config.md || "$path" == .copier-answers.yml ]] && continue
  if grep -Eq '(^|[^[:xdigit:]])[[:xdigit:]]{32}([^[:xdigit:]]|$)' -- "$path" 2>/dev/null; then
    identity_found=true
    break
  fi
done < <(git ls-files -z --cached --others --exclude-standard)

if [[ "$identity_found" == true ]]; then
  printf 'deployment-shaped 32-character identifier found outside the canonical config\n' >&2
  exit 1
fi

printf 'template contract is valid\n'
