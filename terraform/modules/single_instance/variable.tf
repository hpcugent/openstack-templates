variable "vm_name" {
  type    = string
}
variable "image_name" {
  type    = string
}
variable "access_key" {
  default = "default"
}
variable "flavor_name" {
  type    = string
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
variable "floatingip_address" {
}
variable "nfs_size" {
  default = 10
}
variable "public" {
  default = true
  type    = bool
}

variable "volumes" {
  type = map(object({
    size = number
  }))
  default = {}
}
variable "custom_secgroup_rules" {
  type = map(object({
    port = number
    remote_ip_prefix = string
    protocol = string
  }))
  default = {}
}
variable "rootdisk_size" {
  default = "default"
}
variable "is_windows" {
  type = bool
}

variable "persistent_root" {
  type = bool
}
