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
resource "openstack_compute_keypair_v2" "web-cluster-ssh-key" {
  name       = "web-cluster-ssh-key"
  public_key = "${file("${var.ssh_key_file}.pub")}"
}

# -----------------------------------------------------
# Red privada para las maquinas
# -----------------------------------------------------
resource "openstack_networking_network_v2" "web-cluster-private-net" {
  name           = "web-cluster-private-net"
  admin_state_up = "true"
}

# -----------------------------------------------------
# Subred con rango 10.0.10.xxx y DNS de Google
# -----------------------------------------------------
resource "openstack_networking_subnet_v2" "web-cluster-private-subnet" {
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
  name             = "web-cluster-router"
  admin_state_up   = "true"
  external_gateway = "${var.public_net}"
}

# -----------------------------------------------------
# Interface de red que asocia router y red privada
# -----------------------------------------------------
resource "openstack_networking_router_interface_v2" "web-cluster-router-interface" {
  router_id = "${openstack_networking_router_v2.web-cluster-router.id}"
  subnet_id = "${openstack_networking_subnet_v2.web-cluster-private-subnet.id}"
}

# -----------------------------------------------------
# Security group para SSH, HTTP y ICMP
# -----------------------------------------------------
resource "openstack_compute_secgroup_v2" "web-cluster-secgroup" {
  name        = "web-cluster-secgroup"
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
resource "openstack_compute_instance_v2" "web-server" {
  count    = "${var.cluster_size}"
  name     = "web-server-${count.index}"
  image_id = "${var.image_selected}"

  flavor_name     = "${var.flavor_name}"
  key_pair        = "${openstack_compute_keypair_v2.web-cluster-ssh-key.name}"
  security_groups = ["${openstack_compute_secgroup_v2.web-cluster-secgroup.name}"]

  #floating_ip = "${element(openstack_compute_floatingip_v2.web-server-floatip.*.address,count.index)}"

  depends_on = ["openstack_compute_keypair_v2.web-cluster-ssh-key",
    "openstack_networking_subnet_v2.web-cluster-private-subnet",
    "openstack_compute_secgroup_v2.web-cluster-secgroup",
    "openstack_lb_loadbalancer_v2.web-server-loadbalancer",
  ]
  metadata {
    this = "web-server"
  }
  network {
    uuid           = "${openstack_networking_network_v2.web-cluster-private-net.id}"
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
resource "openstack_compute_floatingip_v2" "web-server-floatip" {
  pool       = "${var.pool}"
  depends_on = ["openstack_networking_router_interface_v2.web-cluster-router-interface"]
}

# -----------------------------------------------------
# Balanceador de carga
# -----------------------------------------------------
resource "openstack_lb_loadbalancer_v2" "web-server-loadbalancer" {
  name          = "LBAAS for Web Cluster"
  vip_subnet_id = "${openstack_networking_subnet_v2.web-cluster-private-subnet.id}"

  #vip_address    = "${openstack_compute_floatingip_v2.web-server-floatip.address}"
  vip_address    = "${var.lbass_ip}"
  admin_state_up = "true"

  depends_on = ["openstack_compute_floatingip_v2.web-server-floatip",
    "openstack_networking_subnet_v2.web-cluster-private-subnet",
  ]
}

# -----------------------------------------------------
# Listener del balanceador
# -----------------------------------------------------
resource "openstack_lb_listener_v2" "web-server-lb-listener" {
  protocol        = "HTTP"
  protocol_port   = "80"
  loadbalancer_id = "${openstack_lb_loadbalancer_v2.web-server-loadbalancer.id}"
  depends_on      = ["openstack_lb_loadbalancer_v2.web-server-loadbalancer"]
}

# -----------------------------------------------------
# Pool de conexion al balanceador
# -----------------------------------------------------
resource "openstack_lb_pool_v2" "web-server-lb-pool" {
  protocol    = "HTTP"
  listener_id = "${openstack_lb_listener_v2.web-server-lb-listener.id}"
  lb_method   = "ROUND_ROBIN"
  depends_on  = ["openstack_lb_listener_v2.web-server-lb-listener"]
}

# -----------------------------------------------------
# Añadimos clientes al pool del balanceador
# -----------------------------------------------------
resource "openstack_lb_member_v2" "web-server-lb-member" {
  count         = "${var.cluster_size}"
  pool_id       = "${openstack_lb_pool_v2.web-server-lb-pool.id}"
  subnet_id     = "${openstack_networking_subnet_v2.web-cluster-private-subnet.id}"
  address       = "${element(openstack_compute_instance_v2.web-server.*.access_ip_v4,count.index)}"
  protocol_port = "8080"

  depends_on = ["openstack_lb_pool_v2.web-server-lb-pool",
    "openstack_compute_instance_v2.web-server",
  ]
}

# -----------------------------------------------------
# Healtcheck para HTTP
# -----------------------------------------------------
resource "openstack_lb_monitor_v2" "web-server-lb-monitor" {
  pool_id        = "${openstack_lb_pool_v2.web-server-lb-pool.id}"
  type           = "HTTP"
  delay          = "30"
  timeout        = "10"
  max_retries    = "5"
  url_path       = "/index.html"
  expected_codes = "200"

  depends_on = ["openstack_lb_pool_v2.web-server-lb-pool",
    "openstack_compute_instance_v2.web-server",
    "openstack_lb_member_v2.web-server-lb-member",
  ]
}
