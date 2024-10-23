locals {
  ansible_env={
    ANSIBLE_REMOTE_PORT = local.ports.ssh
    ANSIBLE_REMOTE_USER = local.ssh_user
    ANSIBLE_HOST_KEY_CHECKING = false
  }
  ansible_command="timeout 4m ansible-playbook -c ssh -i ${data.openstack_networking_floatingip_v2.public.address},"
}