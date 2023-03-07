# https://console.hetzner.cloud/projects

# Your Hetzner Cloud API token
hcloud_token   = "YOUR_API_TOKEN"
# The name of the SSH key that will be added to the servers
hcloud_ssh_key = "NAME_OF_SSH_KEY"
# Path to the SSH private key that will be used to access the servers when provisioning
# Must be the same key as the one in the previous variable
auth_key       = "~/.ssh/id_ed25519"

# Resource settings
cloud = ({
  zone          = "eu-central"   # Datacenter zone (eu-central, us-west, etc.)
  location      = "nbg1"         # Datacenter location (nbg1, fsn1, etc.)
  # Networking
  net_name      = "k8s-net"      # Network name (displayed in Hetzner Cloud console)
  net_id        = "10.98.0."     # The network ID to use for the servers, e.g. "192.168.0.", "10.1.0.", etc
  net_mask      = "16"           # The network mask to use for the servers, e.g. "24", "16", etc. Make sure net_id and net_mask are compatible
  # Load Balancer
  lb_name       = "k8s-lb"       # Load balancer name (displayed in Hetzner Cloud console)
  lb_type       = "lb11"         # Load balancer type (lb11, lb21, etc.)
  lb_host_id    = 2              # The network ID to use for the load balancer (will be appended to net_id)
  # Servers
  image         = "ubuntu-22.04" # Distro image to use for the servers
  # Master
  master_name   = "master-1"     # Master server name
  master_type   = "cx21"         # Master server type (cx11, cx21, etc.)
  # Workers
  worker_prefix = "node-"        # Each worker will be named "node-1", "node-2", etc.
  worker_type   = "cx21"         # Worker server type (cx11, cx21, etc.)
  workers       = 2              # Number of worker servers to create
})


