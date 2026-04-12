# ── Azure Identity ─────────────────────────────────────────────────────────────

variable "tenant_id" {
  description = "Azure AD (Entra ID) tenant ID. Supply via ARM_TENANT_ID env var or tfvars. Never commit to source control."
  type        = string
  sensitive   = true
}

variable "subscription_id" {
  description = "Azure subscription ID where all resources will be deployed. Supply via ARM_SUBSCRIPTION_ID env var or tfvars."
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "Client ID of the Service Principal / App Registration used for OIDC authentication. Supply via ARM_CLIENT_ID env var or tfvars."
  type        = string
  sensitive   = true
}

# ── Environment ────────────────────────────────────────────────────────────────

variable "env" {
  description = "Environment name. Controls resource naming and is embedded in all tags."
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "env must be one of: dev, staging, prod."
  }
}

variable "location" {
  description = "Azure region for all resources (e.g. eastus, westeurope)."
  type        = string
  default     = "eastus"
}

# ── Networking ─────────────────────────────────────────────────────────────────

variable "vnet_address_space" {
  description = "CIDR block for the Virtual Network (e.g. 10.0.0.0/16)."
  type        = string
  default     = "10.0.0.0/16"
}

variable "aci_subnet_cidr" {
  description = "CIDR for the ACI workload subnet. Must be within vnet_address_space."
  type        = string
  default     = "10.0.1.0/24"
}

variable "vm_subnet_cidr" {
  description = "CIDR for the dev VM subnet. Must be within vnet_address_space."
  type        = string
  default     = "10.0.2.0/24"
}

# ── Container ──────────────────────────────────────────────────────────────────

variable "container_image" {
  description = "Docker image for the ACI container workload. Pin to a digest or specific tag for production."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "container_port" {
  description = "TCP port exposed by the container inside the VNet."
  type        = number
  default     = 80
}

variable "container_cpu" {
  description = "CPU cores allocated to the container (e.g. 0.5, 1, 2)."
  type        = number
  default     = 0.5
}

variable "container_memory_gb" {
  description = "Memory in GB allocated to the container."
  type        = number
  default     = 0.5
}

# ── AVD ────────────────────────────────────────────────────────────────────────

variable "avd_workspace_friendly_name" {
  description = "Display name shown to developers in the AVD web client and Windows App."
  type        = string
  default     = "Developer Workspace"
}

# ── AVD Users ──────────────────────────────────────────────────────────────────

variable "avd_users" {
  description = "Map of Entra ID users to provision for AVD. Key = username prefix (e.g. 'avduser' → avduser@<tenant-domain>). Each user receives 'Desktop Virtualization User' on the App Group and 'Virtual Machine User Login' on the VM. Keep out of source control — supply via tfvars."
  type = map(object({
    display_name = string
    password     = string
  }))
  sensitive = true
  default   = {}
}

# ── Dev VM ─────────────────────────────────────────────────────────────────────

variable "vm_size" {
  description = "Azure VM size for the Windows dev machine. Minimum Standard_B2ms for AVD/Windows dev."
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "Local admin username for the Windows VM. Avoid common names like 'admin' or 'administrator'."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Windows VM local admin password. Must be 12+ chars with uppercase, lowercase, digit, and symbol. Never commit to source control."
  type        = string
  sensitive   = true
}

variable "os_disk_size_gb" {
  description = "Size in GB for the VM OS disk. Windows Server 2022 requires at least 128 GB for dev workloads."
  type        = number
  default     = 128
}

variable "data_disk_size_gb" {
  description = "Size in GB for the persistent data disk (survives VM reimages). Developer files live here."
  type        = number
  default     = 64
}

variable "data_disk_storage_type" {
  description = "Storage SKU for the persistent data disk. Premium_LRS recommended for dev performance."
  type        = string
  default     = "Premium_LRS"
}