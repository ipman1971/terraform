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
    from_port   = 8080
    to_port     = 8080
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
# Instancia de maquina para web-server
# -----------------------------------------------------
resource "openstack_compute_instance_v2" "web_server" {
  count    = "${var.cluster_size}"
  name     = "web-server-${count.index}"
  image_id = "${var.image_selected}"

  flavor_name     = "${var.flavor_name}"
  key_pair        = "${openstack_compute_keypair_v2.keys_1.name}"
  security_groups = ["${openstack_compute_secgroup_v2.web_cluster_secgroup.name}"]

  #floating_ip = "${element(openstack_compute_floatingip_v2.floatip_1.*.address,count.index)}"

  depends_on = ["openstack_compute_keypair_v2.keys_1",
    "openstack_compute_secgroup_v2.web_cluster_secgroup",
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
                  nohup busybox httpd -f -p 8080 &
              EOF
}

# -----------------------------------------------------
# Ip flotante
# -----------------------------------------------------
resource "openstack_compute_floatingip_v2" "floatip_1" {
  pool       = "${var.pool}"
  depends_on = ["openstack_networking_router_interface_v2.router_interface_1"]
}

# -----------------------------------------------------
# Balanceador de carga
# -----------------------------------------------------
resource "openstack_lb_loadbalancer_v2" "loadbalancer_1" {
  name          = "LBAAS for Web Cluster"
  vip_subnet_id = "${openstack_networking_subnet_v2.subnet_1.id}"
  vip_address   = "${openstack_compute_floatingip_v2.floatip_1.address}"

  depends_on = ["openstack_compute_floatingip_v2.floatip_1",
    "openstack_networking_subnet_v2.subnet_1",
  ]
}

# -----------------------------------------------------
# Listener del balanceador
# -----------------------------------------------------
resource "openstack_lb_listener_v2" "lb_listener_1" {
  protocol        = "HTTP"
  protocol_port   = "80"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.loadbalancer_1.id}"
  depends_on      = ["openstack_lb_loadbalancer_v2.loadbalancer_1"]
}

# -----------------------------------------------------
# Pool de conexion al balanceador
# -----------------------------------------------------
resource "openstack_lb_pool_v2" "lb_pool_1" {
  protocol    = "HTTP"
  listener_id = "${openstack_lb_listener_v2.lb_listener_1.id}"
  lb_method   = "ROUND_ROBIN"
  depends_on  = ["openstack_lb_listener_v2.lb_listener_1"]
}

# -----------------------------------------------------
# Añadimos clientes al pool del balanceador
# -----------------------------------------------------
resource "openstack_lb_member_v2" "lb_member" {
  count         = "${var.cluster_size}"
  pool_id       = "${openstack_lb_pool_v2.lb_pool_1.id}"
  subnet_id     = "${openstack_networking_subnet_v2.subnet_1.id}"
  address       = "${element(openstack_compute_instance_v2.web_server.*.access_ip_v4,count.index)}"
  protocol_port = "8080"

  depends_on = ["openstack_lb_pool_v2.lb_pool_1",
    "openstack_compute_instance_v2.web_server",
  ]
}

# -----------------------------------------------------
# Healtcheck para HTTP
# -----------------------------------------------------
resource "openstack_lb_monitor_v2" "lb_monitor" {
  pool_id        = "${openstack_lb_pool_v2.lb_pool_1.id}"
  type           = "HTTP"
  delay          = "30"
  timeout        = "10"
  max_retries    = "5"
  url_path       = "/index.html"
  expected_codes = "200"

  depends_on = ["openstack_lb_pool_v2.lb_pool_1",
    "openstack_compute_instance_v2.web_server",
    "openstack_lb_member_v2.lb_member",
  ]
}
