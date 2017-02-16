# -----------------------------------------------------
# Instance IP
# -----------------------------------------------------
output "web-cluser-floating-ip" {
  value = "${openstack_compute_floatingip_v2.floatip_1.address}"
}

output "web-cluster-ip-list" {
  value = ["${openstack_compute_instance_v2.web_server.*.access_ip_v4}"]
}
