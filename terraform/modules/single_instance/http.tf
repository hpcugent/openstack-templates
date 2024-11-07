resource "openstack_networking_portforwarding_v2" "http" {
  count               = var.nginx_enabled ? 1 : 0
  floatingip_id       = data.openstack_networking_floatingip_v2.public.id
  external_port       = local.ports.http
  internal_port       = 80
  internal_port_id    = openstack_networking_port_v2.vm.id
  internal_ip_address = openstack_networking_port_v2.vm.all_fixed_ips[0]
  protocol            = "tcp"
  depends_on          = [openstack_networking_secgroup_rule_v2.http, shell_script.port_http]
  lifecycle {
    precondition {
      condition     = var.public
      error_message = ("Cant enable forward on a private instance!")
    }
    replace_triggered_by = [terraform_data.http_port]
    ignore_changes = [ description ] #because otherwise provider crashes
  }
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-http-80"
}
resource terraform_data http_port {
  # stupid work around for terraform being unable to cope with optional replaced_triggered_by
  input = local.ports.http
}
resource "openstack_networking_portforwarding_v2" "https" {
  count               = var.nginx_enabled ? 1 : 0
  floatingip_id       = data.openstack_networking_floatingip_v2.public.id
  external_port       = local.ports.https
  internal_port       = 443
  internal_port_id    = openstack_networking_port_v2.vm.id
  internal_ip_address = openstack_networking_port_v2.vm.all_fixed_ips[0]
  protocol            = "tcp"
  depends_on          = [openstack_networking_secgroup_rule_v2.http]
  lifecycle {
    precondition {
      condition     = var.public
      error_message = ("Cant enable forward on a private instance!")
    }
    replace_triggered_by = [terraform_data.http_port.output]
  }
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-http-443"
}
resource "openstack_networking_secgroup_rule_v2" "http" {
  count             = var.nginx_enabled ? 1 : 0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-http"
}
resource "openstack_networking_secgroup_rule_v2" "https" {
  count             = var.nginx_enabled ? 1 : 0
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 443
  port_range_max    = 443
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.secgroup.id
  description = "${data.openstack_identity_auth_scope_v3.scope.user_name}-${var.vm_name}-http"
}

resource "null_resource" "nginx" {
  count = ( var.nginx_enabled && local.scripts_enabled ) ? 1 : 0
  triggers = {
    enabled = var.nginx_enabled
    user = local.ssh_user
    port = local.ports.ssh
    ip = data.openstack_networking_floatingip_v2.public.address
  }
  depends_on = [ null_resource.testconnection ]
  connection {
    user     = self.triggers.user
    host     = self.triggers.ip
    port = self.triggers.port
    timeout = "2m"
  }
  provisioner "remote-exec" {
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/nginx.yaml --extra-vars install=${self.triggers.enabled}" ]
  }
  provisioner "remote-exec" {
    when = destroy
    on_failure = continue
    inline = [ "sudo ansible-playbook /opt/vsc/ansible/nginx.yaml --extra-vars install=false" ]
  }
}
