# -----------------------------------------------------
# IPs de web-cluster
# -----------------------------------------------------
output "web-cluster-ip-list" {
  value = ["${openstack_compute_instance_v2.web-server.*.access_ip_v4}"]
}
