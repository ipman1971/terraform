# -----------------------------------------------------
# Lista de zonas de disponibilidad
# -----------------------------------------------------
output "availability-zone-list" {
  value = ["${var.avZ}"]
}

# -----------------------------------------------------
# Instancias por zona de disponibilidad
# -----------------------------------------------------
output "instances-by-availability-zone" {
  value = ["${var.cluster_size}"]
}

# -----------------------------------------------------
# Istancias totales para el servicio de web server
# -----------------------------------------------------
output "total-instances" {
  value = "${var.cluster_size} + ${var.avZ}"
}

# -----------------------------------------------------
# IPs de web-cluster
# -----------------------------------------------------
output "web-cluster-ip-list" {
  value = ["${openstack_compute_instance_v2.web-server.*.access_ip_v4}"]
}

output "data_json" {
  value = "${data.template_file.data_json.rendered}"
}
