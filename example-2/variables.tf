# -----------------------------------------------------
# Openstack credentials
# -----------------------------------------------------
variable "image_selected" {
  default = "1d3593f7-26ef-464e-9936-9fedce135e04"
}

variable "user_name" {
  default = "devops"
}

variable "password" {}

variable "project" {
  default = "iac-dev"
}

variable "auth_url" {
  default = "http://javamaster.ovh:5000/v2.0"
}

# -----------------------------------------------------
# Access to instances
# -----------------------------------------------------
variable "user_instance" {
  default = "debian"
}

variable "ssh_key_file" {
  default = "../key-pairs/instance.key"
}

variable "flavor_name" {
  default = "ds512M"
}

variable "cluster_size" {
  description = "Número de instancias que formaran el cluster"
}

# -----------------------------------------------------
# Connection to world
# -----------------------------------------------------
variable "pool" {
  default = "public"
}

variable "public_net" {
  default = "4626acf5-0c3a-4900-916c-946e06a4ac06"
}
