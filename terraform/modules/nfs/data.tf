data "openstack_networking_network_v2" "nfs" {
  name = "${var.project_name}_nfs"
}
data "openstack_networking_subnet_ids_v2" "nfs" {
    network_id = data.openstack_networking_network_v2.nfs.id
}