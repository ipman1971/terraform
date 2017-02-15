# Configure the OpenStack Provider
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.project}"
  password    = "${var.password}"
  auth_url    = "${var.auth_url}"
}

# Definimos clave publica
resource "openstack_compute_keypair_v2" "keys_1" {
  name       = "keys_1"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

# Creamos la red interna para el cluster
resource "openstack_networking_network_v2" "net_1" {
  name           = "net_1"
  admin_state_up = "true"
}

# Creamos la subred con rango de IPs = 10.0.10.xxx , DNS de Google
resource "openstack_networking_subnet_v2" "subnet_1" {
  name            = "subnet_1"
  network_id      = "${openstack_networking_network_v2.net_1.id}"
  cidr            = "10.0.10.0/24"
  ip_version      = "4"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# Creamos un router para conectar la red privada a donde corresponda
resource "openstack_networking_router_v2" "router_1" {
  name           = "router_1"
  admin_state_up = "true"
}

# Interface de red que asocia el router y la red privada
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

# Creamos reglas para ssh y http
resource "openstack_compute_secgroup_v2" "web_cluster_secgroup" {
  name        = "web_cluster_secgroup"
  description = "Security group for Web Clusters"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }

  rule {
    from_port   = -1
    to_port     = -1
    ip_protocol = "icmp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_compute_floatingip_v2" "floating_ip_1" {
  pool       = "${var.pool}"
  depends_on = ["openstack_networking_router_interface_v2.router_interface_1"]
}

#Creamos instancia de maquina
resource "openstack_compute_instance_v2" "web_server" {
  name            = "web-server"
  image_id        = "${var.image_selected}"
  flavor_id       = "d5c40ec5-61ee-45b7-846e-c6c8a657d542"
  flavor_name     = "ds512M"
  key_pair        = "${openstack_compute_keypair_v2.keys_1.name}"
  security_groups = ["${openstack_compute_secgroup_v2.web_cluster_secgroup.name}"]

  #floating_ip     = "${openstack_compute_floatingip_v2.floating_ip_1.address}"

  network {
    uuid           = "${openstack_networking_network_v2.net_1.id}"
    access_network = true
  }

  # Instalamos Nginx
  #provisioner "remote-exec" {
  #  connection {
  #    user        = "${var.user_name}"
  #    private_key = "${file(var.ssh_key_file)}"
  #  }

  #  inline = [
  #    "sudo apt-get -y update",
  #    "sudo apt-get -y install nginx",
  #    "sudo service nginx start",
  #  ]
  #}
}
