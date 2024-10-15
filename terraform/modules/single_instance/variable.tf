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
  description = "A shell script that is executed when the instance is created."
}
variable "cloudinit" {
  type = map(object({
    content_type = string
    content = string
  }))
  default = {}
  description = "A cloud-init part, see https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config"
}
variable "alt_http" {
  type = bool
  default = false
  description = "select a random port for http"
}