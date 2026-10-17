variable "cloudflare_api_token" {
  description = "Scoped Cloudflare API token supplied as a sensitive HCP workspace variable."
  type        = string
  sensitive   = true
}
