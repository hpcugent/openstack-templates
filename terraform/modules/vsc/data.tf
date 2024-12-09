data "openstack_networking_network_v2" "vsc" {
  name = "${var.project_name}_vsc"
}
data "openstack_networking_subnet_ids_v2" "vsc" {
  network_id = data.openstack_networking_network_v2.vsc.id
}
data "openstack_networking_network_v2" "vsc_internal" {
  name = "vsc"
}
resource "shell_script" "vsc_ip_id" {
  count = var.override_ip == null ? 1 : 0
  environment = {
    OS_CLOUD = var.cloud
  }
  lifecycle_commands {
    create = <<EOF
    openstack floating ip list --network ${data.openstack_networking_network_v2.vsc_internal.id} -f json | jq '.[] | select((.Port=="${openstack_networking_port_v2.vsc.id}") or (.Port==null))'
    EOF
    delete = ""
  }
}
