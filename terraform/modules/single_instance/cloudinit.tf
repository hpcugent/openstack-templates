data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"
    content = file("${local.scripts_dir}/cloud-config.yaml")
  }
  part {
    filename     = "userscript.sh"
    content_type = "text/x-shellscript"
    content = var.userscript
  }
  part {
    filename = "install_common.sh"
    content_type = "text/x-shellscript"
    content = <<-EOF
    #!/bin/bash
    if [[ -r '/etc/debian_version' ]];then 
      apt-get update && apt-get install -y cron
    fi
    EOF
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
