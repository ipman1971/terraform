# -----------------------------------------------------
# Configuramos el provider para Openstack
# -----------------------------------------------------
provider "openstack" {
  user_name   = "${var.user_name}"
  tenant_name = "${var.project}"
  password    = "${var.password}"
  auth_url    = "${var.auth_url}"
}

# -----------------------------------------------------
# Definicion de claves para acceso a maquinas
# -----------------------------------------------------
resource "openstack_compute_keypair_v2" "keys_1" {
  name       = "keys_1"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

# -----------------------------------------------------
# Red privada para las maquinas
# -----------------------------------------------------
resource "openstack_networking_network_v2" "net_1" {
  name           = "net_1"
  admin_state_up = "true"
}

# -----------------------------------------------------
# Subred con rango 10.0.10.xxx y DNS de Google
# -----------------------------------------------------
resource "openstack_networking_subnet_v2" "subnet_1" {
  name            = "subnet_1"
  network_id      = "${openstack_networking_network_v2.net_1.id}"
  cidr            = "10.0.10.0/24"
  ip_version      = "4"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# -----------------------------------------------------
# Router para conectar la red privada a
# la red publica
# -----------------------------------------------------
resource "openstack_networking_router_v2" "router_1" {
  name             = "router_1"
  admin_state_up   = "true"
  external_gateway = "${var.public_net}"
}

# -----------------------------------------------------
# Interface de red que asocia router y red privada
# -----------------------------------------------------
resource "openstack_networking_router_interface_v2" "router_interface_1" {
  router_id = "${openstack_networking_router_v2.router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
}

# -----------------------------------------------------
# Security group para SSH, HTTP y ICMP
# -----------------------------------------------------
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

# -----------------------------------------------------
# Ip flotante
# -----------------------------------------------------
resource "openstack_compute_floatingip_v2" "floatip_1" {
  count      = "${var.cluster_size}"
  pool       = "${var.pool}"
  depends_on = ["openstack_networking_router_interface_v2.router_interface_1"]
}

# -----------------------------------------------------
# Instancia de maquina para web-server
# -----------------------------------------------------
resource "openstack_compute_instance_v2" "web_server" {
  count    = "${var.cluster_size}"
  name     = "web-server-${count.index}"
  image_id = "${var.image_selected}"

  flavor_name     = "${var.flavor_name}"
  key_pair        = "${openstack_compute_keypair_v2.keys_1.name}"
  security_groups = ["${openstack_compute_secgroup_v2.web_cluster_secgroup.name}"]

  floating_ip = "${element(openstack_compute_floatingip_v2.floatip_1.*.address,count.index)}"

  depends_on = ["openstack_compute_keypair_v2.keys_1", "openstack_compute_secgroup_v2.web_cluster_secgroup",
    "openstack_compute_floatingip_v2.floatip_1",
    "openstack_networking_network_v2.net_1",
  ]

  metadata {
    this = "web-server"
  }

  network {
    uuid           = "${openstack_networking_network_v2.net_1.id}"
    access_network = true
  }

  # -----------------------------------------------------
  # Provision de Nginx
  # -----------------------------------------------------
  user_data = <<-EOF
                  #!/bin/bash
                  echo "Hello, Terraform World" > index.html
                  nohup busybox httpd -f -p 80 &
              EOF
}
