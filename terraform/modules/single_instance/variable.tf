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
variable "http_port" {
  type = number
  default = 80
  validation {
    condition = var.http_port == 80 || var.http_port >= 50000 && var.http_port <= 60000
    error_message = "Custom port should be between 50000 and 60000!"
  }
}
variable "https_port" {
  type = number
  default = 443
  validation {
    condition = var.https_port == 443 || var.https_port >= 50000 && var.https_port <= 60000
    error_message = "Custom port should be between 50000 and 60000!"
  }
}