resource "openstack_compute_instance_v2" "instance_01" {
  name = var.vm_name
  image_name = var.image_name
  flavor_name = var.flavor_name
  key_pair = var.access_key

  network {
    port = "${openstack_networking_port_v2.port_01_vm_network.id}"
  }
  network {
    port = "${openstack_networking_port_v2.port_01_vsc_network.id}"
  }
}

resource "openstack_compute_secgroup_v2" "ssh-access" {
  name        = "ssh-access"
  description = "a security group"

  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_port_v2" "port_01_vm_network" {
  network_id         = var.vm_network_id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.ssh-access.id}"]

  fixed_ip {
    subnet_id  = var.vm_subnet_id
  }
}

resource "openstack_networking_port_v2" "port_01_vsc_network" {
  network_id         = var.vsc_network_id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.ssh-access.id}"]

  fixed_ip {
    subnet_id  = var.vsc_subnet_id
  }
}

resource "openstack_networking_portforwarding_v2" "pf_terraform-instance_01" {
  floatingip_id    = var.floating_ip_id
  external_port    = var.ssh_forwarded_port
  internal_port    = 22
  internal_port_id = "${openstack_networking_port_v2.port_01_vm_network.id}"
  internal_ip_address = "${openstack_networking_port_v2.port_01_vm_network.all_fixed_ips[0]}"
  protocol         = "tcp"
}

resource "openstack_networking_floatingip_associate_v2" "fip_01_vsc_network" {
  floating_ip = var.vsc_floating_ip
  port_id     = "${openstack_networking_port_v2.port_01_vsc_network.id}"
}
