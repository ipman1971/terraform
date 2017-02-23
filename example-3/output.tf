# -----------------------------------------------------
# Lista de zonas de disponibilidad
# -----------------------------------------------------
output "availability-zone-list" {
  value = ["${var.avZ}"]
}

# -----------------------------------------------------
# Istancias totales para el servicio de web server
# -----------------------------------------------------
output "total-instances" {
  value = "${var.cluster_size}"
}

# -----------------------------------------------------
# IPs de web-cluster
# -----------------------------------------------------
output "web-cluster-ip-list" {
  value = ["${openstack_compute_instance_v2.web-server.*.access_ip_v4}"]
}
