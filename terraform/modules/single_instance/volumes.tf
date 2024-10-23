resource "openstack_blockstorage_volume_v3" "custom_volume" {
  for_each = var.volumes
  name = each.key
  size = each.value.size
  enable_online_resize = true
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-${each.key}"
}

resource "openstack_compute_volume_attach_v2" "custom_volume" {
  for_each = openstack_blockstorage_volume_v3.custom_volume
  instance_id = openstack_compute_instance_v2.instance_01.id
  volume_id   = each.value.id
}
resource "null_resource" "filesystem" {
  for_each = {
    for k, v in openstack_compute_volume_attach_v2.custom_volume : k => merge(v, { filesystem = var.volumes[k].filesystem, size = var.volumes[k].size, automount = var.volumes[k].automount })
    if var.volumes[k].automount && var.is_windows == false
  }
  triggers = {
    filesystem = each.value.filesystem
    device = each.value.device
    size = each.value.size
    ansible_command = local.ansible_command
    ansible_env = jsonencode(local.ansible_env)
  }
  depends_on = [ null_resource.testconnection ]
  provisioner "local-exec" {
    environment = local.ansible_env
    command  = <<-EOT
    ${self.triggers.ansible_command} ${local.scripts_dir}/ansible/create_or_resize.yaml -e "filesystem=${self.triggers.filesystem} device=${self.triggers.device}"
    EOT
  }
}
resource "null_resource" "volumeMount" {
  for_each = {
    for k, v in openstack_compute_volume_attach_v2.custom_volume : k => merge(v, { filesystem = var.volumes[k].filesystem, size = var.volumes[k].size, automount = var.volumes[k].automount })
    if var.volumes[k].automount && var.is_windows == false
  }
  triggers = {
    name = each.key
    filesystem = each.value.filesystem
    device = each.value.device
    ansible_command = local.ansible_command
    scripts_dir = local.scripts_dir
    ansible_env = jsonencode(local.ansible_env)
  }
  depends_on = [ null_resource.filesystem]
  provisioner "local-exec" {
    environment = local.ansible_env
    command  = <<-EOT
    ${self.triggers.ansible_command} ${local.scripts_dir}/ansible/mount_vol.yaml -e "mount=true vol_name=${self.triggers.name} filesystem=${self.triggers.filesystem} device=${self.triggers.device}"
    EOT
  }
  provisioner "local-exec" {
    when = destroy
    on_failure = continue
    environment = jsondecode(self.triggers.ansible_env)
    command  = "${self.triggers.ansible_command} ${self.triggers.scripts_dir}/ansible/mount_vol.yaml -e \"mount=false vol_name=${self.triggers.name} filesystem=${self.triggers.filesystem} device=${self.triggers.device}\""
  }
}
