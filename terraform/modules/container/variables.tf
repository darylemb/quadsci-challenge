variable "env" {
  description = "Environment name. Used in resource naming."
  type        = string
}

variable "location" {
  description = "Azure region."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group to deploy the container group into."
  type        = string
}

variable "subnet_id" {
  description = "ID of the ACI subnet (snet-aci). Must have the ContainerInstance delegation."
  type        = string
}

variable "container_image" {
  description = "Docker image to run."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 80
}

variable "cpu" {
  description = "CPU cores allocated to the container."
  type        = number
  default     = 0.5
}

variable "memory_gb" {
  description = "Memory in GB allocated to the container."
  type        = number
  default     = 0.5
}

variable "tags" {
  description = "Tags to apply to resources."
  type        = map(string)
  default     = {}
}
