variable "instance_id" {

}
variable "security_group_id" {

}
variable "project_name" {

}
variable "cloud" {

}
variable "vm_name" {
  
}
variable "user_name" {
  
}
variable "host" {
  type = object({
    ip = string
    port = string
    user = string
    scripts_enabled = bool
  })
}
variable "override_ip" {
  type = string
  default = null
}
