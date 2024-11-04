data "openstack_networking_network_v2" "nfs" {
  name = "${data.openstack_identity_project_v3.project.name}_nfs_vxlan"
}
data "openstack_networking_subnet_ids_v2" "nfs" {
  network_id = data.openstack_networking_network_v2.nfs.id
}
data "openstack_identity_auth_scope_v3" "scope" {
  name = "scope"
}
data "openstack_identity_project_v3" "project" {
  name = data.openstack_identity_auth_scope_v3.scope.project_name
}
data "openstack_networking_subnet_v2" "nfs" {
  name = "${data.openstack_identity_project_v3.project.name}_nfs_vxlan_pool"
}

