variable "vm_name" {
}
variable "image_name" {

}
variable "access_key" {
  default = "default"
}
variable "flavor_name" {
}
variable "nfs_enabled" {
  default = false
  type    = bool
}
variable "nginx_enabled" {
  default = false
  type    = bool
}
variable "vsc_enabled" {
  default = false
  type    = bool
}
variable "playbook_url" {
  default = "https://raw.githubusercontent.com/hpcugent/openstack-templates/master/heat/playbooks/install_nginx.yaml"
}
variable "project_name" {
  default = "default"
}
variable "nfs_size" {
  default = 10
}
variable "cloud" {
  default = "openstack"
}
variable "public" {
  default = true
  type    = bool
}

variable "volumes" {
  type = map(object({
    size = number
    fstype = string
  }))
  default = {}
}