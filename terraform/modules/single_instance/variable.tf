locals {
  ugent_port_range = {
    min = 51001
    max = 59999
  }
}

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
variable "project_name" {
  default = "default"
}
variable "floatingip_address" {
  default = null
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
    fastpool = optional(bool,false)
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
    external_port = optional(number,null)
  }))
  default = {}
  validation {
    condition = (
      anytrue(
        [for v in var.custom_secgroup_rules :
          v.external_port >= local.ugent_port_range.min &&
          v.external_port <= local.ugent_port_range.max
      ])

    )
    error_message = "External port must be between ${local.ugent_port_range.min} and ${local.ugent_port_range.max}"
  }
}
variable "rootdisk_size" {
  default = "default"
}
variable "is_windows" {
  type = bool
}

variable "persistent_root" {
  type = bool
  default = false
}
variable "rootvolume_fastpool" {
  type = bool
  default = false
}
variable "userscript"{
  type = string
  default = <<-EOF
  #!/bin/sh
  exit 0
  EOF 
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
variable "scripts_enabled" {
  type = bool
  default = true
  description = "Enables or disables local ansible scripts"
}
variable "vsc_ip" {
  type = string
  default = null
  description = "override VSC dedicated IP"
}
variable "nfs_network" {
  type = bool
  default = false
  description = "Enable the NFS network"
}
variable "ssh_user" {
  type = string
  default = null
  description = "Default ssh user for the image."
}
