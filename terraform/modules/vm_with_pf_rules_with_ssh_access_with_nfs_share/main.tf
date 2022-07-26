data "template_file" "user_data_instance_01" {
  template = file("../scripts/mount.sh")
  vars = {
    _SHARE_ = "${openstack_sharedfilesystem_share_v2.share_01.export_locations[0].path}"
  }
}

resource "openstack_compute_instance_v2" "instance_01" {
  name = var.vm_name
  flavor_name = var.flavor_name
  key_pair = var.access_key
  user_data = data.template_file.user_data_instance_01.rendered

  block_device {
    uuid                  = var.image_id
    source_type           = "image"
    volume_size           = var.root_fs_volume_size
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }

  network {
    port = "${openstack_networking_port_v2.port_01_vm_network.id}"
  }
  network {
    port = "${openstack_networking_port_v2.port_01_nfs_network.id}"
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

resource "openstack_networking_port_v2" "port_01_nfs_network" {
  network_id         = var.nfs_network_id
  admin_state_up     = "true"
  security_group_ids = ["${openstack_compute_secgroup_v2.ssh-access.id}"]

  fixed_ip {
    subnet_id  = var.nfs_subnet_id
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

resource "openstack_sharedfilesystem_share_v2" "share_01" {
  name = var.share_name
  size = var.share_size
  share_proto = "NFS"
}

resource "openstack_sharedfilesystem_share_access_v2" "share_01_access" {
  share_id     = "${openstack_sharedfilesystem_share_v2.share_01.id}"
  access_type  = "ip"
  access_to    = "0.0.0.0"
  access_level = "rw"
}

