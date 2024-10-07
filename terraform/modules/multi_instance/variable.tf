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
variable "userscript" {
  type = string
  default = ""
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
variable "public_secgroup_rules" {
  type = map(object({
    port = number
    remote_ip_prefix = string
    protocol = string
    expose = optional(bool,false)
  }))
  default = {}
}