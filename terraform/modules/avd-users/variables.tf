variable "users" {
  description = "Map of AVD users to provision. The key becomes the username prefix before @domain (e.g. key 'avduser' → avduser@contoso.onmicrosoft.com). Each user receives 'Desktop Virtualization User' on the App Group and 'Virtual Machine User Login' on the VM."
  type = map(object({
    display_name = string
    password     = string
  }))
  sensitive = true
}

variable "app_group_id" {
  description = "Resource ID of the AVD Desktop Application Group."
  type        = string
}

variable "vm_id" {
  description = "Resource ID of the AVD session host VM."
  type        = string
}
