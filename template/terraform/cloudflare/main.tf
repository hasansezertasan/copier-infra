locals {
  config_path          = "${path.root}/../../.infra-copilot/config.md"
  config_document      = file(local.config_path)
  infra_copilot_config = yamldecode(regex("(?s)\\A---\\n(.*?)\\n---\\n", local.config_document)[0])
}

# This read-only lookup proves that the HCP workspace token can access the configured
# zone. Add managed resources in separate, purpose-named files after setup.
data "cloudflare_zone" "configured" {
  zone_id = local.infra_copilot_config.cloudflare_zone_id

  lifecycle {
    postcondition {
      condition = (
        self.name == local.infra_copilot_config.apex_domain &&
        self.account.id == local.infra_copilot_config.cloudflare_account_id
      )
      error_message = "The configured Cloudflare zone, domain, and account do not match."
    }
  }
}
