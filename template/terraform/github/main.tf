locals {
  config_path          = "${path.root}/../../.infra-copilot/config.md"
  config_document      = file(local.config_path)
  infra_copilot_config = yamldecode(regex("(?s)\\A---\\n(.*?)\\n---\\n", local.config_document)[0])
  managed_repositories = toset([
    for repository in local.infra_copilot_config.managed_repos : basename(repository)
  ])
}

# This lookup always exists, so configuration invariants remain blocking even when
# managed_repos is accidentally empty.
data "github_organization" "configured" {
  name         = local.infra_copilot_config.github_org
  summary_only = true

  lifecycle {
    precondition {
      condition = (
        var.github_owner == local.infra_copilot_config.github_org &&
        length(local.infra_copilot_config.managed_repos) > 0 &&
        alltrue([
          for repository in local.infra_copilot_config.managed_repos :
          length(regexall("^[^/]+/[^/]+$", repository)) == 1 &&
          startswith(repository, "${local.infra_copilot_config.github_org}/")
        ])
      )
      error_message = "github_owner must match github_org, and managed_repos must contain at least one complete github_org/repository name."
    }
  }
}

# These read-only lookups prove that the GitHub App can access every configured
# repository. Add managed resources in separate, purpose-named files after setup.
data "github_repository" "managed" {
  for_each = local.managed_repositories
  name     = each.value
}
