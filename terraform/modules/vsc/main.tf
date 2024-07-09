resource "openstack_networking_floatingip_associate_v2" "vsc" {
  floating_ip = data.shell_script.vsc_ip_id.output["Floating IP Address"]
  port_id     = openstack_networking_port_v2.vsc.id
  lifecycle {
    ignore_changes = [floating_ip] # shell script will return a new address so we ignore changes to it
  }
}
resource "openstack_networking_port_v2" "vsc" {
  network_id         = data.openstack_networking_network_v2.vsc.id
  admin_state_up     = "true"
  security_group_ids = ["${var.security_group_id}"]

  fixed_ip {
    subnet_id = data.openstack_networking_subnet_ids_v2.vsc.ids[0]
  }
  name = "${var.user_name}-${var.vm_name}-vsc"
  tags = [ var.user_name, var.vm_name ]
}



resource "openstack_compute_interface_attach_v2" "vsc_attach" {
  instance_id = var.instance_id
  port_id     = openstack_networking_port_v2.vsc.id
}
