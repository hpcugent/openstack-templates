
resource "openstack_networking_port_v2" "nfs" {
  network_id         = data.openstack_networking_network_v2.nfs.id
  admin_state_up     = "true"
  security_group_ids = var.security_group_ids

  fixed_ip {
    subnet_id = data.openstack_networking_subnet_ids_v2.nfs.ids[0]
  }
  tags = [ var.user_name, var.vm_name ]
  description = "${var.user_name}-${var.vm_name}-nfs"

}
resource "openstack_compute_interface_attach_v2" "ai_1" {
  instance_id = var.instance_id
  port_id     = openstack_networking_port_v2.nfs.id
}
resource "openstack_sharedfilesystem_share_v2" "share_01" {
  name        = var.share_name
  size        = var.share_size
  share_proto = "NFS"
  description = "${var.user_name}-${var.vm_name}"
}

resource "openstack_sharedfilesystem_share_access_v2" "share_01_access" {
  share_id     = openstack_sharedfilesystem_share_v2.share_01.id
  access_type  = "ip"
  access_to    = "0.0.0.0"
  access_level = "rw"
}
