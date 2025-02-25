resource "openstack_blockstorage_volume_v3" "custom_volume" {
  for_each = var.volumes
  name = each.key
  size = each.value.size
  enable_online_resize = true
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-${each.key}"
  volume_type = each.value.fastpool ? "fastpool" : "tripleo"
}

resource "openstack_compute_volume_attach_v2" "custom_volume" {
  for_each = openstack_blockstorage_volume_v3.custom_volume
  instance_id = openstack_compute_instance_v2.instance_01.id
  volume_id   = each.value.id
}
resource "null_resource" "volumes" {
  for_each = {
    for k, v in openstack_compute_volume_attach_v2.custom_volume : k => merge(v,{filesystem = var.volumes[k].filesystem,size = var.volumes[k].size})
    if var.volumes[k].automount == true && local.scripts_enabled
  }
  triggers = {
    user = local.ssh_user
    port = local.ports.ssh
    ip = data.openstack_networking_floatingip_v2.public.address
    name = each.key
    filesystem = each.value.filesystem
    device = each.value.device
  }
  depends_on = [ terraform_data.filesystem ]
  connection {
    user     = self.triggers.user
    host     = self.triggers.ip
    port = self.triggers.port
  }
  provisioner "remote-exec" {
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/mount_vol.yaml -e \"mount=true vol_name=${self.triggers.name} filesystem=${self.triggers.filesystem} device=${self.triggers.device}\"" ]
  }
  provisioner "remote-exec" {
    when = destroy
    on_failure = continue
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/mount_vol.yaml -e \"mount=false vol_name=${self.triggers.name} filesystem=${self.triggers.filesystem} device=${self.triggers.device}\"" ]
  }
}
resource "terraform_data" "filesystem" {
  for_each = {
    for k, v in openstack_compute_volume_attach_v2.custom_volume : k => merge(v,{filesystem = var.volumes[k].filesystem,size = var.volumes[k].size})
    if var.volumes[k].automount == true && local.scripts_enabled
  }
  triggers_replace = [each.value.size]
  depends_on = [ null_resource.testconnection ]
  connection {
    user     = local.ssh_user
    host     = data.openstack_networking_floatingip_v2.public.address
    port = local.ports.ssh
  }
  provisioner "remote-exec" {
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/create_or_resize.yaml -e \"filesystem=${each.value.filesystem} device=${each.value.device}\"" ]
  }
}
