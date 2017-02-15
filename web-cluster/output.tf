output "web-cluser-ip" {
  value = "[${openstack_compute_floatingip_v2.floatip_1.address}]"
}
