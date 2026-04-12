###############################################################################
# Devbox Module — Windows VM (AVD Session Host)
#
# Deploys a Windows Server 2022 VM for remote development with:
#   - No public IP — access via Azure Virtual Desktop (reverse-connect)
#   - AAD (Entra ID) join — no domain controller required
#   - Registered as an AVD Personal Session Host
#   - Persistent data disk (Premium LRS) — survives VM reimages
#
# Access flow:
#   Developer → browser or Windows App → AVD web client
#     → AVD reverse-connect (outbound 443 from VM via NAT GW)
#       → full Windows desktop session
#
# Persistence:
#   A dedicated managed data disk (LUN 0) is attached to the VM.
#   It persists across reboots and reimages. Store working data on D:\ or
#   a custom mount point initialized on first boot via a custom script.
###############################################################################

# ── Network Interface (no public IP) ─────────────────────────────────────────

resource "azurerm_network_interface" "this" {
  name                = "nic-devbox-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig-devbox"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id — intentionally omitted
  }

  tags = var.tags
}

# ── Windows Virtual Machine ───────────────────────────────────────────────────

resource "azurerm_windows_virtual_machine" "this" {
  name                = "vm-devbox-${var.env}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [azurerm_network_interface.this.id]

  os_disk {
    name                 = "osdisk-devbox-${var.env}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb         = var.os_disk_size_gb
  }

  # Windows Server 2022 Datacenter Azure Edition
  # PAYG — no additional Windows license required
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  # Required for AVD: VM agent must be provisioned
  provision_vm_agent       = true
  enable_automatic_updates = true
  patch_assessment_mode    = "AutomaticByPlatform"
  patch_mode               = "AutomaticByPlatform"

  # Boot diagnostics — managed storage account
  boot_diagnostics {}

  # Identity needed for AAD join extension
  identity {
    type = "SystemAssigned"
  }

  # Prevent Terraform from reimaging the VM when rotating admin_password
  lifecycle {
    ignore_changes = [admin_password]
  }

  tags = var.tags
}

# ── Persistent Data Disk ──────────────────────────────────────────────────────

resource "azurerm_managed_disk" "data" {
  name                 = "disk-data-devbox-${var.env}"
  location             = var.location
  resource_group_name  = var.resource_group_name
  storage_account_type = var.data_disk_storage_type
  create_option        = "Empty"
  disk_size_gb         = var.data_disk_size_gb

  lifecycle {
    # Prevent accidental deletion of the persistent data disk in production.
    # Set to false only when explicitly decommissioning the environment.
    prevent_destroy = false
  }

  tags = var.tags
}

resource "azurerm_virtual_machine_data_disk_attachment" "data" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_windows_virtual_machine.this.id
  lun                = 0
  caching            = "ReadWrite"
}

# ── Extension 0: Data Disk Initialisation ────────────────────────────────────
# On first boot the attached managed disk has no partition table (RAW).
# This script detects it and formats it as GPT/NTFS with label "DevData".
# Idempotent: the Get-Disk filter only matches RAW disks so subsequent runs
# are no-ops once the disk is already initialised.

resource "azurerm_virtual_machine_extension" "disk_init" {
  name                       = "disk-init"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Compute"
  type                       = "CustomScriptExtension"
  type_handler_version       = "1.10"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    commandToExecute = "powershell -NonInteractive -ExecutionPolicy Unrestricted -Command \"$disk = Get-Disk | Where-Object { $_.PartitionStyle -eq 'RAW' }; if ($disk) { $disk | Initialize-Disk -PartitionStyle GPT -PassThru | New-Partition -AssignDriveLetter -UseMaximumSize | Format-Volume -FileSystem NTFS -NewFileSystemLabel DevData -Confirm:$false }\""
  })

  depends_on = [azurerm_virtual_machine_data_disk_attachment.data]
  tags       = var.tags
}

# ── Extension 1: AAD (Entra ID) Join ─────────────────────────────────────────
# Joins the VM to Azure Active Directory — no domain controller required.
# Required before the AVD DSC extension runs.

resource "azurerm_virtual_machine_extension" "aad_login" {
  name                       = "AADLoginForWindows"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Azure.ActiveDirectory"
  type                       = "AADLoginForWindows"
  type_handler_version       = "2.0"
  auto_upgrade_minor_version = true

  tags = var.tags
}

# ── Extension 2: AVD Session Host Registration (DSC) ─────────────────────────
# Installs the RD Agent and Boot Loader, then registers the VM into the
# AVD Host Pool using the registration token (passed via protected_settings
# to avoid storing it in plaintext in Terraform state).

resource "azurerm_virtual_machine_extension" "avd_dsc" {
  name                       = "microsoft-powershell-dsc-avd"
  virtual_machine_id         = azurerm_windows_virtual_machine.this.id
  publisher                  = "Microsoft.Powershell"
  type                       = "DSC"
  type_handler_version       = "2.73"
  auto_upgrade_minor_version = true

  settings = jsonencode({
    modulesUrl            = var.avd_dsc_artifact_url
    configurationFunction = "Configuration.ps1\\AddSessionHost"
    properties = {
      HostPoolName = var.host_pool_name
      aadJoin      = true
    }
  })

  # Registration token goes in protected_settings — encrypted at rest in state
  protected_settings = jsonencode({
    properties = {
      RegistrationInfoToken = var.registration_token
    }
  })

  # AAD join must complete before DSC registration
  depends_on = [azurerm_virtual_machine_extension.aad_login]

  tags = var.tags
}