# -----------------------------------------------------
# Instance IP
# -----------------------------------------------------
output "web-server-ip" {
  value = "${openstack_compute_instance_v2.web-server.access_ip_v4}"
}
