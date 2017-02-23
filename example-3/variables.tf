# -----------------------------------------------------
# Openstack credentials
# -----------------------------------------------------
variable "image_selected" {
  description = "Identificador de la imagen con la que se crean las instancias"
  default     = "1d3593f7-26ef-464e-9936-9fedce135e04"
}

variable "user_name" {
  description = "usuario de openstack"
  default     = "devops"
}

variable "password" {
  description = "password para acceso a openstack"
}

variable "project" {
  description = "nombrel de proyecto o tenant"
  default     = "iac-dev"
}

variable "auth_url" {
  description = "endpoint para acceso a openstack"
  default     = "http://javamaster.ovh:5000/v2.0"
}

variable "region" {
  description = "region"
  default     = "RegionOne"
}

variable "avZ" {
  description = "zonas de disponibilidad de una region"
  type        = "list"
  default     = ["zone-1", "zone-2", "zone-3"]
}

variable "instances_by_avZ" {
  description = "numero de instancias por zona de disponibilidad"
  default     = "2"
}

# -----------------------------------------------------
# Access to instances
# -----------------------------------------------------
variable "user_instance" {
  description = "usuario de la imagen que se instala en las instancias"
  default     = "debian"
}

variable "ssh_key_file" {
  description = "par de claves para acceso a las instancias"
  default     = "../key-pairs/instance.key"
}

variable "flavor_name" {
  description = "tipo de instancia"
  default     = "ds512M"
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
  description = "red de acceso publico"
  default     = "4626acf5-0c3a-4900-916c-946e06a4ac06"
}
