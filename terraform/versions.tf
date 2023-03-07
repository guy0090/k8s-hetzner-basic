# Manage the versions of the providers used in this project
terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "=1.36.2"
    }
  }
}
