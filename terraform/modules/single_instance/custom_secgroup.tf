
resource openstack_networking_secgroup_rule_v2 "custom" {
  for_each = var.custom_secgroup_rules
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = each.value.protocol
  port_range_min    = each.value.port
  port_range_max    = each.value.port
  remote_ip_prefix  = each.value.remote_ip_prefix
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-${each.key}"
}
resource "shell_script" "custom_portforward" {
  for_each =  {
    for k, v in var.custom_secgroup_rules:  k => v
    if var.custom_secgroup_rules[k].expose == true
  }
  environment = {
    "IP_ID"      = data.openstack_networking_floatingip_v2.public.id
    "PORT_COUNT" = 1
    "PORT_NAME"  = "${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_${each.key}"
    "OS_CLOUD"   = local.cloud
  }
  lifecycle_commands {
    create = file("../scripts/generate_port.sh")
    delete = <<-EOF
      rm -rf "port_${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_${each.key}.json"
    EOF
    read   = <<-EOF
      cat "port_${var.vm_name}-${substr(random_uuid.uuid.result, 0, 4)}_${each.key}.json"
    EOF
  }
  working_directory = path.root
  interpreter       = ["/bin/bash", "-c"]
}
resource "openstack_networking_portforwarding_v2" "custom" {
  for_each =  {
    for k, v in var.custom_secgroup_rules:  k => merge(v,{external_port = jsondecode(shell_script.custom_portforward[k].output["ports"])[0] })
    if var.custom_secgroup_rules[k].expose == true
  }
  floatingip_id       = data.openstack_networking_floatingip_v2.public.id
  external_port       = each.value.external_port
  internal_port       = each.value.port
  internal_port_id    = openstack_networking_port_v2.vm.id
  internal_ip_address = openstack_networking_port_v2.vm.all_fixed_ips[0]
  protocol            = "tcp"
  lifecycle {
    precondition {
      condition     = var.public
      error_message = ("Cant enable forward on a private instance!")
    }
    replace_triggered_by = [ openstack_networking_secgroup_rule_v2.custom[each.key] ]
  }
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-${each.key}"
}
locals {
  custom_ports=trimspace(<<PORTS
%{for k,v in openstack_networking_portforwarding_v2.custom ~}
${k} ${v.internal_port} -> ${data.openstack_networking_floatingip_v2.public.address}:${v.external_port}
%{endfor}
PORTS
  )
}
