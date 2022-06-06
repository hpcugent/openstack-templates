module "vm_with_pf_rules_with_ssh_access" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access"

  vm_name              = "MyVM"
  floating_ip_id       = "dd8b33b1-d178-4229-9df6-00157c61181c"
  vm_network_id        = "985df437-2555-471d-9836-48355e6e7e9b"
  vm_subnet_id         = "05f58ec4-5b6c-466a-9f18-78aac2ccf9f6"
  access_key           = "ssh-rsa AAAAB3Nz_Lxyy1Q__ root_charon"
  image_name           = "CentOS-8-stream"
  flavor_name          = "CPUv1.small"
  ssh_forwarded_port   = "52201"
}

module "vm_with_pf_rules_with_ssh_access_with_nginx" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access_with_nginx"

  vm_name              = "MyVM"
  floating_ip_id       = "dd8b33b1-d178-4229-9df6-00157c61181c"
  vm_network_id        = "985df437-2555-471d-9836-48355e6e7e9b"
  vm_subnet_id         = "05f58ec4-5b6c-466a-9f18-78aac2ccf9f6"
  access_key           = "ssh-rsa AAAAB3Nz_Lxyy1Q__ root_charon"
  image_name           = "CentOS-8-stream"
  flavor_name          = "CPUv1.small"
  ssh_forwarded_port   = "52202"
  http_forwarded_port  = "8088"
  ansible_playbook_url = "https://raw.githubusercontent.com/hpcugent/openstack-templates/master/heat/playbooks/install_nginx.yaml"
}

module "vm_with_pf_rules_with_ssh_access_with_vsc_net" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access_with_vsc_net"

  vm_name              = "MyVM"
  floating_ip_id       = "dd8b33b1-d178-4229-9df6-00157c61181c"
  vsc_floating_ip      = "172.24.48.5"
  vm_network_id        = "985df437-2555-471d-9836-48355e6e7e9b"
  vm_subnet_id         = "05f58ec4-5b6c-466a-9f18-78aac2ccf9f6"
  vsc_network_id       = "fc52017a-51d2-4c8a-8e31-e2e402d81010"
  vsc_subnet_id        = "5af88a7e-b5f1-4f71-8716-0533b555d619"
  access_key           = "ssh-rsa AAAAB3Nz_Lxyy1Q__ root_charon"
  image_name           = "CentOS-8-stream"
  flavor_name          = "CPUv1.small"
  ssh_forwarded_port   = "52203"
}

module "vm_with_pf_rules_with_ssh_access_with_nfs_share" {
  source   = "../modules/vm_with_pf_rules_with_ssh_access_with_nfs_share"

  vm_name              = "MyVM"
  floating_ip_id       = "dd8b33b1-d178-4229-9df6-00157c61181c"
  vm_network_id        = "985df437-2555-471d-9836-48355e6e7e9b"
  vm_subnet_id         = "05f58ec4-5b6c-466a-9f18-78aac2ccf9f6"
  nfs_network_id       = "2bab49b1-c5d1-48be-a670-911c46db53ad"
  nfs_subnet_id        = "5c6b72d5-5245-4406-b52f-0b347364ac50"
  access_key           = "ssh-rsa AAAAB3Nz_Lxyy1Q__ root_charon"
  image_name           = "CentOS-8-stream"
  flavor_name          = "CPUv1.small"
  ssh_forwarded_port   = "52204"
  share_name           = "MyShare"
  share_size           = "10"
}

