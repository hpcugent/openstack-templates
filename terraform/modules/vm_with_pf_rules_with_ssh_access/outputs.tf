output "VM_ip_address" {
  value = openstack_networking_port_v2.port_01_vm_network.all_fixed_ips
}
