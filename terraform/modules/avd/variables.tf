variable "env" {
  description = "Environment name."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy AVD resources into."
  type        = string
}

variable "workspace_friendly_name" {
  description = "Display name for the AVD Workspace (shown in the client)."
  type        = string
  default     = "Developer Workspace"
}

variable "tags" {
  description = "Tags to apply to all AVD resources."
  type        = map(string)
  default     = {}
}