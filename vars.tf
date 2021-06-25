variable "prefix" {
  default = "poc"
  description = "Prefix for the resource names"
}

variable "instance_count" {
  default = 3
  description = "Number of instances to be deployed"
}

variable "resource_group_name" {
  description = "The name of the resource group that the resources will run in"
}

variable "location" {
  description = "The name of the region that the resources will run in"
}

variable "admin_username" {
  description = "The administrator account name for the VM"
  sensitive   = true
}

variable "admin_password" {
  description = "The administrator account password for the VM"
  sensitive   = true
}

variable "vm_size" {
  default = "Standard_B2s"
  description = "The size of the VM"
}
