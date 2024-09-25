
data "cloudinit_config" "main" {
  gzip          = false
  base64_encode = false
  part {
    filename     = "cloud-config.yaml"
    content_type = "text/cloud-config"

    content = templatefile("${local.scripts_dir}/cloud-config.yaml", { resizescript = file("${local.scripts_dir}/create_or_resize.sh") })
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
