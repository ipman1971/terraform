variable "ssh_key_file" {
  default = "./key-pairs/devops-web-cluster.key"
}

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
  default = "http://46.4.91.51:5000/v2.0"
}

variable "pool" {
  default = "public"
}
