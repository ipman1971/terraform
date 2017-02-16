# -----------------------------------------------------
# Openstack credentials
# -----------------------------------------------------
variable "image_selected" {
  default = "68f83096-a234-4752-a18d-59994b37f19a"
}

variable "user_name" {
  default = "devops"
}

variable "password" {
  default = "devops"
}

variable "project" {
  default = "web-cluster"
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
  default = "key-pairs/devops-web-cluster.key"
}

variable "flavor_name" {
  default = "ds512M"
}

variable "cluster_size" {
  default = "3"
}

# -----------------------------------------------------
# Connection to world
# -----------------------------------------------------
variable "pool" {
  default = "public"
}

variable "public_net" {
  default = "d6f707ab-bd2b-4beb-bec1-cc8b3a68e12b"
}
