resource "openstack_sharedfilesystem_share_v2" "share" {
  name        = var.name
  size        = var.size
  share_proto = "NFS"
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.name}"
}

resource "openstack_sharedfilesystem_share_access_v2" "default" {
  count = length(var.access_rules) == 0 ? 1 : 0
  share_id     = openstack_sharedfilesystem_share_v2.share.id
  access_type  = "ip"
  access_to    = data.openstack_networking_router_v2.nfs.external_fixed_ip[0].ip_address
  access_level = "rw"
}
resource "openstack_sharedfilesystem_share_access_v2" "rules" {
  for_each = {
    for index, rule in var.access_rules : index => rule
  } 
  share_id     = openstack_sharedfilesystem_share_v2.share.id
  access_type  = each.value.access_type
  access_to    = each.value.access_to
  access_level = each.value.access_level
}
