# ── Azure Identity ─────────────────────────────────────────────────────────────

variable "subscription_id" {
  description = "Azure subscription ID. Used for Contributor role scope and provider config."
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Entra ID (Azure AD) tenant ID."
  type        = string
  sensitive   = true
}

# ── App Registration ───────────────────────────────────────────────────────────

variable "app_name" {
  description = "Display name for the Azure AD App Registration."
  type        = string
  default     = "github-actions-quadsci"
}

# ── Optional ───────────────────────────────────────────────────────────────────

variable "tfstate_storage_account_id" {
  description = "Resource ID of the Terraform state storage account. Assign 'Storage Blob Data Contributor'. Leave empty to skip (add later with terraform apply)."
  type        = string
  default     = ""
}
