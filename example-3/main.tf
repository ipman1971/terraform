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
# Definicion de claves para acceso a la instancias
# -----------------------------------------------------
resource "openstack_compute_keypair_v2" "web-cluster-ssh-key" {
  name       = "web-cluster-ssh-key"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

# -----------------------------------------------------
# Red privada para las instancias
# -----------------------------------------------------
resource "openstack_networking_network_v2" "web-cluster-private-net" {
  region         = "${var.region}"
  name           = "web-cluster-private-net"
  admin_state_up = "true"
}

# -----------------------------------------------------
# Subred con rango 10.0.10.xxx y DNS de Google
# -----------------------------------------------------
resource "openstack_networking_subnet_v2" "web-cluster-private-subnet" {
  region          = "${var.region}"
  name            = "web-cluster-private-subnet"
  network_id      = "${openstack_networking_network_v2.web-cluster-private-net.id}"
  cidr            = "10.0.10.0/24"
  ip_version      = "4"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

# -----------------------------------------------------
# Router para conectar la red privada a
# la red publica
# -----------------------------------------------------
resource "openstack_networking_router_v2" "web-cluster-router" {
  region           = "${var.region}"
  name             = "web-cluster-router"
  admin_state_up   = "true"
  external_gateway = "${var.public_net}"
}

# -----------------------------------------------------
# Interface de red que asocia router y red privada
# -----------------------------------------------------
resource "openstack_networking_router_interface_v2" "web-cluster-router-interface" {
  region    = "${var.region}"
  router_id = "${openstack_networking_router_v2.web-cluster-router.id}"
  subnet_id = "${openstack_networking_subnet_v2.web-cluster-private-subnet.id}"
}

# -----------------------------------------------------
# Security group para SSH, HTTP y ICMP
# -----------------------------------------------------
resource "openstack_compute_secgroup_v2" "web-cluster-secgroup" {
  region      = "${var.region}"
  name        = "web-cluster-secgroup"
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
# Instancia de maquina web-server
# -----------------------------------------------------
resource "openstack_compute_instance_v2" "web-server" {
  count             = "${var.cluster_size}"
  region            = "${var.region}"
  availability_zone = "${element(var.avZ,count.index)}"
  name              = "${format("ws-%s-%02d",element(var.avZ,count.index),count.index+1)}"
  image_id          = "${var.image_selected}"
  flavor_name       = "${var.flavor_name}"
  key_pair          = "${openstack_compute_keypair_v2.web-cluster-ssh-key.name}"
  security_groups   = ["${openstack_compute_secgroup_v2.web-cluster-secgroup.name}"]

  depends_on = ["openstack_compute_keypair_v2.web-cluster-ssh-key",
    "openstack_networking_subnet_v2.web-cluster-private-subnet",
    "openstack_compute_secgroup_v2.web-cluster-secgroup",
  ]

  metadata {
    this = "web-cluster"
  }

  network {
    uuid           = "${openstack_networking_network_v2.web-cluster-private-net.id}"
    access_network = true
  }

  user_data = <<-EOF
                  #!/bin/bash
                  echo "Hello, Terraform World" > index.html
                  nohup busybox httpd -f -p 80 &
              EOF
}

# -----------------------------------------------------
# Fichero de resultados
# -----------------------------------------------------
data "template_file" "data_json" {
  template = "${var.datafile_template}"

  vars {
    availability_zone_list = "${join(",",var.avZ)}"
    cluster_size           = "${var.cluster_size}"
    web-cluster_ip_list    = "${join(",",openstack_compute_instance_v2.web-server.*.access_ip_v4)}"
  }

  provisioner "local-exec" {
    command = "cat << EOF > ./data.json \n${template_file.data_json.rendered}"
  }
}
