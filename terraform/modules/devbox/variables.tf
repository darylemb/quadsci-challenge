variable "env" {
  description = "Environment name. Used in resource naming and tagging."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy the VM and related resources into."
  type        = string
}

variable "subnet_id" {
  description = "ID of the VM subnet (snet-vm)."
  type        = string
}

variable "vm_size" {
  description = "Size of the VM SKU. Minimum recommended for Windows dev: Standard_B2ms."
  type        = string
  default     = "Standard_B2ms"
}

variable "admin_username" {
  description = "Local admin username for the Windows VM."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Local admin password for the Windows VM. Must meet Azure complexity requirements (12+ chars, uppercase, lowercase, digit, symbol)."
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.admin_password) >= 12
    error_message = "admin_password must be at least 12 characters long."
  }

  validation {
    condition     = can(regex("[A-Z]", var.admin_password))
    error_message = "admin_password must contain at least one uppercase letter."
  }

  validation {
    condition     = can(regex("[a-z]", var.admin_password))
    error_message = "admin_password must contain at least one lowercase letter."
  }

  validation {
    condition     = can(regex("[0-9]", var.admin_password))
    error_message = "admin_password must contain at least one digit."
  }

  validation {
    condition     = can(regex("[^A-Za-z0-9]", var.admin_password))
    error_message = "admin_password must contain at least one special character."
  }
}

variable "os_disk_size_gb" {
  description = "Size in GB of the OS disk. Windows Server 2022 requires at least 128 GB for dev workloads."
  type        = number
  default     = 128
}

variable "data_disk_size_gb" {
  description = "Size in GB of the persistent data disk (survives VM reimages)."
  type        = number
  default     = 64
}

variable "data_disk_storage_type" {
  description = "Storage SKU for the persistent data disk."
  type        = string
  default     = "Premium_LRS"

  validation {
    condition     = contains(["Premium_LRS", "StandardSSD_LRS", "Standard_LRS", "UltraSSD_LRS"], var.data_disk_storage_type)
    error_message = "data_disk_storage_type must be one of: Premium_LRS, StandardSSD_LRS, Standard_LRS, UltraSSD_LRS."
  }
}

# ── AVD Session Host Registration ─────────────────────────────────────────────

variable "host_pool_name" {
  description = "Name of the AVD Host Pool to register this VM into."
  type        = string
}

variable "registration_token" {
  description = "AVD registration token (from avd module output). Passed to the DSC extension via protected_settings."
  type        = string
  sensitive   = true
}

variable "avd_dsc_artifact_url" {
  description = "URL to the AVD DSC configuration zip artifact. Pin to a specific version for production."
  type        = string
  default     = "https://wvdportalstorageblob.blob.core.windows.net/galleryartifacts/Configuration_09-08-2022.zip"
}

variable "dev_tools_packages" {
  description = "List of Chocolatey package IDs to pre-install on the dev VM. Set to [] to skip dev tools installation."
  type        = list(string)
  default     = [
    "microsoft-openjdk-21",
    "python",
    "nodejs-lts",
    "vscode",
    "git",
    "maven",
    "gradle",
    "docker-desktop",
    "7zip",
    "googlechrome",
  ]
}

variable "tags" {
  description = "Tags to apply to all devbox resources."
  type        = map(string)
  default     = {}
}