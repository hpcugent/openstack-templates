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
# Mount all automount volumes and create the filesystem
resource "terraform_data" "makeAndMount" {
  for_each = {
    for k, v in openstack_compute_volume_attach_v2.custom_volume : k => merge(v,{filesystem = var.volumes[k].filesystem,size = var.volumes[k].size})
    if var.volumes[k].automount == true && var.is_windows == false
  }
  depends_on = [ openstack_compute_volume_attach_v2.custom_volume, openstack_compute_instance_v2.instance_01 ]
  triggers_replace = each.value.size
  connection {
    type     = "ssh"
    user     = local.ssh_user
    agent = true
    host     = data.openstack_networking_floatingip_v2.public.address
    timeout = "5m"
    port = local.ports.ssh
  }
  provisioner "file" {
    source      = "${local.scripts_dir}/create_or_resize.sh"
    destination = "/tmp/create_or_resize.sh"
  }
  provisioner "remote-exec" {
    # First do some security things, then run the script
    inline = [
      "sudo chown root:root /tmp/create_or_resize.sh",
      "sudo chmod o-rw /tmp/create_or_resize.sh",
      "sudo chmod u+x /tmp/create_or_resize.sh",
      "sudo bash /tmp/create_or_resize.sh ${each.value.device} ${each.key} ${each.value.filesystem}",
      "sudo rm -f /tmp/create_or_resize.sh"
    ]
  }

}
# Runs on destroy to unmount the volume when it is removed from the configuration
resource "null_resource" "unmount" {
  for_each = {
    for k, v in openstack_compute_volume_attach_v2.custom_volume : k => merge(v,{filesystem = var.volumes[k].filesystem,size = var.volumes[k].size})
    if var.volumes[k].automount == true && var.is_windows == false
  }
  depends_on = [ openstack_compute_volume_attach_v2.custom_volume, openstack_compute_instance_v2.instance_01 ]
  # Necessary because of some "dependency loop" prevention in terraform.
  triggers = {
    user = local.ssh_user
    port = local.ports.ssh
    ip = data.openstack_networking_floatingip_v2.public.address
    volume = each.key
  }
  connection {
    type     = "ssh"
    user     = self.triggers.user
    agent = true
    host     = self.triggers.ip
    timeout = "5m"
    port = self.triggers.port
  }
  provisioner "remote-exec" {
    when        = destroy
    on_failure  = continue
    inline = [
      "sudo umount /mnt/${each.key}",
      "sudo rm -rf /mnt/${each.key}"
    ]
  }
}

