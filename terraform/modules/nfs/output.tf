output "nfs_path" {
  value = openstack_sharedfilesystem_share_v2.share_01.export_locations[0].path
}