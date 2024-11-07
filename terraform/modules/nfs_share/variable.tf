variable "name" {
  type = string
  description = "Name of the share"
}
variable "size" {
  type = number
  description = "Size of the share in gigabytes"
}
variable "access_rules" {
  type = list(object({
    access_type  = optional(string,"ip")
    access_to    = string
    access_level = optional(string,"rw")
  }))
  default = []
}
