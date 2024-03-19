variable "cluster_name" {
}
variable "public_image" {

}
variable "private_image" {
  default = "default"
}
variable "access_key" {
  default = "default"
}
variable "private_flavor" {
  default = "default"
}
variable "public_flavor" {

}
variable "public_nginx_enabled" {
  default = false
  type    = bool
}
variable "public_vsc_enabled" {
  default = false
  type    = bool
}
variable "playbook_url" {
  default = "https://raw.githubusercontent.com/hpcugent/openstack-templates/master/heat/playbooks/install_nginx.yaml"
}
variable "project_name" {
  default = "default"
}
variable "cloud" {
  default = "openstack"
}
variable "private_count" {
  type = number
}
locals {
  private_image  = var.private_image == "default" ? var.public_image : var.private_image
  private_flavor = var.private_flavor == "default" ? var.public_flavor : var.private_flavor
}
