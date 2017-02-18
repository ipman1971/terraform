# -----------------------------------------------------
# Openstack credentials
# -----------------------------------------------------
variable "image_selected" {
  default = "8ed72063-82ed-4608-a952-5abfbdf6683c"
}

variable "user_name" {
  default = "devops"
}

variable "password" {
  default = "diamante"
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
  #default = "a5beae4c-fc69-4d8f-936f-d6feb9a56165"
  default = "b7905a26-7ead-400e-bb9b-1240ef8dfdd6"
}

variable "lbass_ip" {
  default = "10.0.10.253"
}
