variable "github_owner" {
  description = "GitHub organization that owns the managed repositories."
  type        = string
}

variable "github_app_id" {
  description = "GitHub App ID supplied as a sensitive HCP workspace variable."
  type        = string
  sensitive   = true
}

variable "github_app_installation_id" {
  description = "GitHub App installation ID supplied as a sensitive HCP workspace variable."
  type        = string
  sensitive   = true
}

variable "github_app_pem" {
  description = "GitHub App private-key contents supplied as a sensitive HCP workspace variable."
  type        = string
  sensitive   = true
}
