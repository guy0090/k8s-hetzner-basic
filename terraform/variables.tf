## Setup variables & hcloud provider
variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  sensitive   = false
}

variable "hcloud_ssh_key" {
  description = "Name of the SSH key to use for the servers"
  sensitive   = false
}

variable "auth_key" {
  description = "Path to the SSH key to use for the provisioner"
  sensitive   = false
  default     = "~/.ssh/id_ed25519"
}

# See .tfvars for values
variable "cloud" {
  description = "Settings for all resources"
  sensitive   = false
}
