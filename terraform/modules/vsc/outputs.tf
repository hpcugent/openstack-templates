output "vsc_floating_ip" {
  value = openstack_networking_floatingip_associate_v2.vsc.floating_ip
}