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
variable "public" {
  default = true
  type    = bool
}

variable "volumes" {
  type = map(object({
    size = number
    automount = optional(bool, false)
    filesystem  = optional(string, "ext4")
  }))
  default = {}
  validation {
    condition = alltrue([for v in var.volumes : v.filesystem == null || contains(["ext4","ext3","ext2"],v.filesystem) ])
    error_message = "Can only auto-create ext2,ext3,ext4!"
  }
  validation {
    condition = !( anytrue([for v in var.volumes : v.automount ]) && var.is_windows )
    error_message = "Can't automount on windows!"
  }
}
variable "custom_secgroup_rules" {
  type = map(object({
    port = number
    remote_ip_prefix = string
    protocol = string
    expose = optional(bool,false)
  }))
  default = {}
}
variable "rootdisk_size" {
  default = "default"
}
variable "is_windows" {
  type = bool
}
variable "userscript"{
  type = string
  default = ""
}
variable "cloudinit" {
  type = map(object({
    content_type = string
    content = string
  }))
  default = {}
}
