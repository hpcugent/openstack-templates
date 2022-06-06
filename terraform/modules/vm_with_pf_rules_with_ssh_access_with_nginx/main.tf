data "template_file" "user_data_instance_01" {
  template = file("../modules/vm_with_pf_rules_with_ssh_access_with_nginx/scripts/run_ansible.sh")
  vars = {
    _ANSIBLE_URL_ = var.ansible_playbook_url
  }
}

resource "openstack_compute_instance_v2" "instance_01" {
  name = var.vm_name
  image_name = var.image_name
  flavor_name = var.flavor_name
  key_pair = var.access_key
  user_data = data.template_file.user_data_instance_01.rendered

  network {
    port = "${openstack_networking_port_v2.port_01_vm_network.id}"
  }
}

resource "openstack_compute_secgroup_v2" "ssh-http-access" {
  name        = "ssh-http-access"
  description = "a security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
    rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_port_v2" "port_01_vm_network" {
  network_id         = var.vm_network_id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.ssh-http-access.id}"]

  fixed_ip {
    subnet_id  = var.vm_subnet_id
  }
}

resource "openstack_networking_portforwarding_v2" "pf_terraform-ssh-instance_01" {
  floatingip_id    = var.floating_ip_id
  external_port    = var.ssh_forwarded_port
  internal_port    = 22
  internal_port_id = "${openstack_networking_port_v2.port_01_vm_network.id}"
  internal_ip_address = "${openstack_networking_port_v2.port_01_vm_network.all_fixed_ips[0]}"
  protocol         = "tcp"
}

resource "openstack_networking_portforwarding_v2" "pf_terraform-http-instance_01" {
  floatingip_id    = var.floating_ip_id
  external_port    = var.http_forwarded_port
  internal_port    = 80
  internal_port_id = "${openstack_networking_port_v2.port_01_vm_network.id}"
  internal_ip_address = "${openstack_networking_port_v2.port_01_vm_network.all_fixed_ips[0]}"
  protocol         = "tcp"
}
