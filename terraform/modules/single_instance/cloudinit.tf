data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${local.scripts_dir}/cloud-config.yaml", { files = data.local_file.ansible })
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

resource "null_resource" "testconnection" {
  count = var.is_windows ? 0 : 1
  depends_on = [ openstack_compute_instance_v2.instance_01 ]
  triggers = {
    user = local.ssh_user
    port = local.ports.ssh
    ip = data.openstack_networking_floatingip_v2.public.address
  }
  provisioner "remote-exec" {
    connection {
      user     = self.triggers.user
      host     = self.triggers.ip
      port = self.triggers.port
      timeout = "5m"
    }
    inline = ["echo 'connected!'"]
  }
}
resource "null_resource" "nginx" {
  count = ( var.nginx_enabled && !var.is_windows) ? 1 : 0
  triggers = {
    enabled = var.nginx_enabled
    scripts_dir = local.scripts_dir
    ansible_command = local.ansible_command
    environment = jsonencode(local.ansible_env)
  }
  depends_on = [ null_resource.testconnection ]
  provisioner "local-exec" {
    environment = jsondecode(self.triggers.environment)
    command = "${self.triggers.ansible_command} ${self.triggers.scripts_dir}/ansible/nginx.yaml --extra-vars install=${self.triggers.enabled}"
  }
  provisioner "local-exec" {
    environment = jsondecode(self.triggers.environment)
    when = destroy
    on_failure = continue
    command=  "${self.triggers.ansible_command} ${self.triggers.scripts_dir}/ansible/nginx.yaml --extra-vars install=false"
  }
}
