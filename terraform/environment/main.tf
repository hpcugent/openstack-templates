module "MyVM" {
  source        = "../modules/single_instance"
  vm_name       = "MyVM"
  image_name    = "Rocky-9"
  flavor_name   = "CPUv1.medium"
  nginx_enabled = false #Webserver, set to true if you need port 80 exposed
  nfs_enabled   = false #Only set true if you requested access
  vsc_enabled   = false #Only set true if you requested access
}
output "MyVM" {
  value = module.MyVM.Connections
}
# module "MyExample" {
#   source        = "../modules/linux_general"
#   cloud         = "openstack" # In case you have access to a different ugent cloud
#   project_name  = "VSC_XXXX" # In case you have access to multiple projects
#   access_key    = "my-key" #ssh access key to install
#   vm_name       = "MyVM"
#   image_name    = "Rocky-9"
#   flavor_name   = "CPUv1.medium"
#   nginx_enabled = false
#   nfs_enabled   = false
#   nfs_size      = 10
#   vsc_enabled   = false
#   playbook_url  = "https://raw.githubusercontent.com/hpcugent/openstack-templates/master/heat/playbooks/install_nginx.yaml"
# }
# output "MyExample" {
#   value = module.MyExample.Connections
# }