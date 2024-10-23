locals {
  ansible_env={
    ANSIBLE_REMOTE_PORT = local.ports.ssh
    ANSIBLE_REMOTE_USER = local.ssh_user
    ANSIBLE_HOST_KEY_CHECKING = false
  }
  ansible_command="timeout 4m ansible-playbook -c ssh -i ${data.openstack_networking_floatingip_v2.public.address},"
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