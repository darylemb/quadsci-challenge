variable "env" {
  description = "Environment name (e.g. dev, staging, prod). Used in resource naming."
  type        = string
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group to create all networking resources in."
  type        = string
}

variable "vnet_address_space" {
  description = "CIDR block for the Virtual Network."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrnetmask(var.vnet_address_space))
    error_message = "vnet_address_space must be a valid CIDR block (e.g. 10.0.0.0/16)."
  }
}

variable "aci_subnet_cidr" {
  description = "CIDR for the ACI workload subnet (internal only, no internet egress)."
  type        = string
  default     = "10.0.1.0/24"

  validation {
    condition     = can(cidrnetmask(var.aci_subnet_cidr))
    error_message = "aci_subnet_cidr must be a valid CIDR block."
  }
}

variable "vm_subnet_cidr" {
  description = "CIDR for the dev VM subnet (has NAT Gateway for outbound internet)."
  type        = string
  default     = "10.0.2.0/24"

  validation {
    condition     = can(cidrnetmask(var.vm_subnet_cidr))
    error_message = "vm_subnet_cidr must be a valid CIDR block."
  }
}

variable "tags" {
  description = "Tags to apply to all networking resources."
  type        = map(string)
  default     = {}
}