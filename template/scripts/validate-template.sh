#!/usr/bin/env bash
set -euo pipefail

root=$(git rev-parse --show-toplevel)
cd "$root"

required_files=(
  README.md
  .copier-answers.yml
  mise.toml
  mise.lock
  terraform/cloudflare/versions.tf
  terraform/cloudflare/backend.tf
  terraform/cloudflare/providers.tf
  terraform/cloudflare/variables.tf
  terraform/cloudflare/main.tf
  terraform/cloudflare/.terraform.lock.hcl
  terraform/github/versions.tf
  terraform/github/backend.tf
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

config_path=README.md

for marker in '<!-- infra:config start -->' '<!-- infra:config end -->' \
  '<!-- infra:decisions start -->' '<!-- infra:decisions end -->' \
  '# infra:customization start' '# infra:customization end'; do
  if [[ $(grep -Fxc "$marker" "$config_path") -ne 1 ]]; then
    printf '%s must contain exactly one "%s" line\n' "$config_path" "$marker" >&2
    exit 1
  fi
done

if grep -Fq 'replace-with-' "$config_path"; then
  printf '%s contains unresolved placeholders\n' "$config_path" >&2
  exit 1
fi

# The Config block is the fenced YAML between the infra:config markers in the README.
config_block() {
  sed -n '/^<!-- infra:config start -->$/,/^<!-- infra:config end -->$/p' "$config_path"
}

config_value() {
  config_block | sed -nE "s/^$1:[[:space:]]*\"?([^\"[:space:]]+)\"?[[:space:]]*\$/\\1/p"
}

backend=$(config_value backend)
case "$backend" in
  hcp) config_keys=(hcp_org hcp_status_check_id) ;;
  object-storage) config_keys=(state_backend state_bucket state_prefix) ;;
  *)
    printf '%s must declare backend: hcp or backend: object-storage\n' "$config_path" >&2
    exit 1
    ;;
esac
config_keys+=(backend github_org apex_domain cloudflare_account_id cloudflare_zone_id managed_repos)

for key in "${config_keys[@]}"; do
  if ! config_block | grep -Eq "^${key}:"; then
    printf '%s is missing %s\n' "$config_path" "$key" >&2
    exit 1
  fi
done

terraform_pin=$(sed -n 's/^terraform = "\([^"]*\)"$/\1/p' mise.toml)
if [[ -z "$terraform_pin" ]]; then
  printf 'mise.toml must contain an exact Terraform pin\n' >&2
  exit 1
fi

for directory in terraform/cloudflare terraform/github; do
  if ! grep -Fq "required_version = \"= $terraform_pin\"" "$directory/versions.tf"; then
    printf '%s/versions.tf must require Terraform %s exactly\n' "$directory" "$terraform_pin" >&2
    exit 1
  fi
done

if [[ "$backend" == hcp ]]; then
  hcp_org=$(config_value hcp_org)
  if [[ -z "$hcp_org" ]]; then
    printf '%s must contain one non-empty hcp_org\n' "$config_path" >&2
    exit 1
  fi
  for directory in terraform/cloudflare terraform/github; do
    if ! grep -Fq "organization = \"$hcp_org\"" "$directory/backend.tf"; then
      printf '%s/backend.tf must use hcp_org from %s\n' "$directory" "$config_path" >&2
      exit 1
    fi
  done
  if ! grep -Fq 'name = "cloudflare"' terraform/cloudflare/backend.tf; then
    printf 'Cloudflare root must bind to the cloudflare workspace\n' >&2
    exit 1
  fi
  if ! grep -Fq 'name = "github-org"' terraform/github/backend.tf; then
    printf 'GitHub root must bind to the github-org workspace\n' >&2
    exit 1
  fi
else
  state_backend=$(config_value state_backend)
  state_bucket=$(config_value state_bucket)
  state_prefix=$(config_value state_prefix)
  for leaf in cloudflare github; do
    file="terraform/$leaf/backend.tf"
    if ! grep -Fq "backend \"$state_backend\"" "$file"; then
      printf '%s must configure the %s backend\n' "$file" "$state_backend" >&2
      exit 1
    fi
    if grep -Eq '^[[:space:]]*cloud[[:space:]]*\{' "$file"; then
      printf '%s must not mix a cloud block with an object-storage backend\n' "$file" >&2
      exit 1
    fi
    if ! grep -Fq "\"$state_bucket\"" "$file"; then
      printf '%s must use state_bucket from %s\n' "$file" "$config_path" >&2
      exit 1
    fi
    if ! grep -Fq "\"$state_prefix/$leaf" "$file"; then
      printf '%s must isolate state under %s/%s\n' "$file" "$state_prefix" "$leaf" >&2
      exit 1
    fi
  done
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

# An S3-compatible endpoint such as Cloudflare R2's embeds the account ID in its host, so the
# configured endpoint itself may appear in the backend blocks; nothing else may.
state_endpoint=''
if [[ "$backend" == object-storage && "$state_backend" == s3 ]]; then
  state_endpoint=$(config_value state_endpoint)
fi

identity_found=false
while IFS= read -r -d '' path; do
  [[ "$path" == .copier-answers.yml ]] && continue
  # Only the README's Config block may hold identifiers; the rest of the README is scanned.
  if [[ "$path" == README.md ]]; then
    content=$(sed '/^<!-- infra:config start -->$/,/^<!-- infra:config end -->$/d' "$path")
  else
    content=$(cat -- "$path" 2>/dev/null || true)
    if [[ -n "$state_endpoint" && "$path" == terraform/*/backend.tf ]]; then
      content=${content//"$state_endpoint"/}
    fi
  fi
  if grep -Eq '(^|[^[:xdigit:]])[[:xdigit:]]{32}([^[:xdigit:]]|$)' <<<"$content"; then
    identity_found=true
    break
  fi
done < <(git ls-files -z --cached --others --exclude-standard)

if [[ "$identity_found" == true ]]; then
  printf 'deployment-shaped 32-character identifier found outside the canonical config\n' >&2
  exit 1
fi

printf 'template contract is valid\n'
