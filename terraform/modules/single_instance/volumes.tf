resource "openstack_blockstorage_volume_v3" "custom_volume" {
  for_each = var.volumes
  name = each.key
  size = each.value.size
}

resource "openstack_compute_volume_attach_v2" "custom_volume" {
  for_each = openstack_blockstorage_volume_v3.custom_volume
  instance_id = openstack_compute_instance_v2.instance_01.id
  volume_id   = each.value.id
}