locals {
  both_enabled = var.nfs_enabled && var.nginx_enabled
  any_enabled  = var.nfs_enabled || var.nginx_enabled
  ports = {
    ssh  = jsondecode(shell_script.port_ssh.output["ports"])[0]
    http = var.nginx_enabled ? jsondecode(shell_script.port_http[0].output["ports"])[0] : null
  }
  ssh_internal_port = var.is_windows ? 3389 : 22
  project_name      = data.openstack_identity_project_v3.project.name
  cloud             = jsondecode(file("${path.root}/terraform.tfvars.json"))["cloud"]
  access_key        = var.access_key == "default" ? data.shell_script.access_key.output["Name"] : var.access_key
  disk_var          = var.rootdisk_size == "default" ? data.openstack_compute_flavor_v2.flavor.disk : var.rootdisk_size
  disk_size         = var.is_windows ? max(local.disk_var,60) : local.disk_var
  scripts_dir       = "${path.module}/scripts"
  userdatafile      = var.userdatafile == "default" ? "${local.scripts_dir}/userdata.sh" : var.userdatafile
}

# UUID for this "instance of the module" rather than depending on a changeable instance ID
resource "random_uuid" "uuid" {
  
}
resource "shell_script" "port_ssh" {
  environment = {
    "IP_ID"      = data.openstack_networking_floatingip_v2.public.id
    "PORT_COUNT" = 1
    "PORT_NAME"  = "${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_ssh"
    "OS_CLOUD"   = local.cloud
  }
  lifecycle_commands {
    create = file("${local.scripts_dir}/generate_port.sh")
    delete = <<-EOF
      rm -rf "port_${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_ssh.json"
    EOF
    read   = <<-EOF
      cat "port_${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_ssh.json"
    EOF
  }
  working_directory = path.root
  interpreter       = ["/bin/bash", "-c"]
}
resource "shell_script" "port_http" {
  count = var.nginx_enabled ? 1 : 0
  environment = {
    "OS_CLOUD"   = local.cloud
    "IP_ID"      = data.openstack_networking_floatingip_v2.public.id
    "PORT_COUNT" = 1
    "PORT_NAME"  = "${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_http"
  }
  lifecycle_commands {
    create = file("${local.scripts_dir}/generate_port.sh")
    delete = <<-EOF
      rm -rf "port_${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_http.json"
    EOF
    read   = <<-EOF
      cat "port_${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_http.json"
    EOF
  }
  working_directory = path.root
  interpreter       = ["/bin/bash", "-c"]
}
data "openstack_identity_auth_scope_v3" "scope" {
  name = "scope"
}
data "openstack_identity_project_v3" "project" {
  name = data.openstack_identity_auth_scope_v3.scope.project_name
}
data "shell_script" "access_key" {
  environment = {
    OS_CLOUD = local.cloud
  }
  lifecycle_commands {
    read = <<EOF
openstack keypair list -f json | jq '.[0]'
    EOF
  }
}
data "openstack_networking_network_v2" "vm" {
  name = "${local.project_name}_vm"
}
data "openstack_networking_subnet_ids_v2" "vm" {
  network_id = data.openstack_networking_network_v2.vm.id
}
data "openstack_compute_flavor_v2" "flavor" {
  name = var.flavor_name
}
data "openstack_images_image_ids_v2" "image" {
  name = var.image_name
}
data "openstack_networking_network_v2" "public" {
  name = "public"
}
data "openstack_networking_floatingip_v2" "public" {
  pool = data.openstack_networking_network_v2.public.id
}
resource "random_string" "winpass" {
  count   = var.is_windows ? 1 : 0
  length  = 16
  special = false
}
