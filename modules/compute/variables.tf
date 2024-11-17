# modules/compute/variables.tf
variable "project_id" {
  description = "GCP Project ID"
  type        = string
}

variable "region" {
  description = "GCP Region"
  type        = string
}

variable "zone" {
  description = "GCP Zone"
  type        = string
}

variable "instance_name" {
  description = "VM Instance Name"
  type        = string
}

variable "machine_type" {
  description = "VM Machine Type"
  type        = string
}

variable "network_name" {
  description = "VPC Network Name"
  type        = string
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
}