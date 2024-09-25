data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${local.scripts_dir}/cloud-config.yaml", { resizescript = file("${local.scripts_dir}/create_or_resize.sh"), files = data.local_file.ansible })
  }
  part {
    filename     = "userscript.sh"
    content_type = "text/x-shellscript"
    content = var.userscript
  }
  dynamic "part" {
    for_each = var.cloudinit
    content {
      filename = part.key
      content_type = part.value.content_type
      content = part.value.content
    }
  }
}
locals {
  ansible_files = fileset("${local.scripts_dir}/ansible/", "**")
}
data "local_file" "ansible" {
  for_each = local.ansible_files
  filename = "${local.scripts_dir}/ansible/${each.value}"
}

resource "time_sleep" "waitforinstall" {
  depends_on = [ openstack_compute_instance_v2.instance_01 ]
  create_duration = "2m"
}

resource "null_resource" "nginx" {
  count = var.nginx_enabled ? 1 : 0
  triggers = {
    enabled = var.nfs_enabled
    user = local.ssh_user
    port = local.ports.ssh
    ip = data.openstack_networking_floatingip_v2.public.address
  }
  depends_on = [ time_sleep.waitforinstall ]
  connection {
    user     = self.triggers.user
    host     = self.triggers.ip
    port = self.triggers.port
  }
  provisioner "remote-exec" {
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/nginx.yaml --extra-vars install=${self.triggers.enabled}" ]
  }
  provisioner "remote-exec" {
    when = destroy
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/nginx.yaml --extra-vars install=false" ]
  }
}
resource "null_resource" "nfs" {
  count = var.nfs_enabled ? 1 : 0
  triggers = {
    enabled = var.nfs_enabled
    path    = module.linux_nfs[0].nfs_path
    user = local.ssh_user
    port = local.ports.ssh
    ip = data.openstack_networking_floatingip_v2.public.address
  }
  depends_on = [ module.linux_nfs[0] ,time_sleep.waitforinstall ]
  connection {
    user     = self.triggers.user
    host     = self.triggers.ip
    port = self.triggers.port
  }
  provisioner "remote-exec" {
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/mount_nfs.yaml -e \"mount=${self.triggers.enabled} nfs_path=${self.triggers.path}\"" ]
  }
    provisioner "remote-exec" {
    when = destroy
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/mount_nfs.yaml -e \"mount=false nfs_path=${self.triggers.path}\"" ]
  }
}
