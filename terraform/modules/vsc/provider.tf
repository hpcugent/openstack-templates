terraform {
  required_providers {
    openstack = {
      source = "terraform-provider-openstack/openstack"
      version = "1.54.1"
    }
    shell = {
      source = "scottwinkler/shell"
      version = "1.7.10"
    }
  }
}