resource "openstack_compute_instance_v2" "instance_01" {
  name = var.vm_name
  flavor_name = var.flavor_name
  key_pair = var.access_key

  block_device {
    uuid                  = var.image_windows_id
    source_type           = "image"
    volume_size           = var.root_fs_volume_size
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  metadata = {
    admin_pass = var.windows_admin_password
  }

  network {
    port = "${openstack_networking_port_v2.port_01_vm_network.id}"
  }
}

resource "openstack_compute_secgroup_v2" "ssh-access" {
  name        = "ssh-access"
  description = "Windows Remote Desktop security group"

  rule {
    from_port   = 3389
    to_port     = 3389
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

resource "openstack_networking_portforwarding_v2" "pf_terraform-ssh-instance_01" {
  floatingip_id    = var.floating_ip_id
  external_port    = var.ssh_forwarded_port
  internal_port    = 3389
  internal_port_id = "${openstack_networking_port_v2.port_01_vm_network.id}"
  internal_ip_address = "${openstack_networking_port_v2.port_01_vm_network.all_fixed_ips[0]}"
  protocol         = "tcp"
}
