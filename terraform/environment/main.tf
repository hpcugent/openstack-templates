module "VM" {
  source        = "../modules/single_instance"
  vm_name       = "Paul-test-VM"
  access_key    = "pubkey_padge"
  image_name    = "Rocky-9"
  flavor_name   = "CPUv1.medium"
  nginx_enabled = false #Webserver, set to true if you need port 80 exposed
  nfs_enabled   = false #Only set true if you requested access
  vsc_enabled   = false #Only set true if you requested access
  is_windows = false
  floatingip_address = "193.190.80.50"
  persistent_root = true
  volumes = {
    vol1 = {
        size = 10
    }
  }
}  
output "VM" {
  value = module.VM.Connections
}
