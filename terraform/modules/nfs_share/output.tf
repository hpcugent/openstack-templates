output "path" {
  value = openstack_sharedfilesystem_share_v2.share.export_locations[0].path
}