# Setup Network
resource "hcloud_network" "net" {
  name     = var.cloud.net_name
  ip_range = "${var.cloud.net_id}0/${var.cloud.net_mask}"
}

# Register Subnet
resource "hcloud_network_subnet" "subnet" {
  network_id   = hcloud_network.net.id
  network_zone = var.cloud.zone
  ip_range     = "${var.cloud.net_id}0/${var.cloud.net_mask}"
  type         = "cloud"
}

# Setup Load Balancer
resource "hcloud_load_balancer" "lb" {
  name               = var.cloud.lb_name
  load_balancer_type = var.cloud.lb_type
  location           = var.cloud.location
}

# Set Load Balancer Network
resource "hcloud_load_balancer_network" "lb-net" {
  load_balancer_id = hcloud_load_balancer.lb.id
  network_id       = hcloud_network.net.id
  ip               = "${var.cloud.net_id}${var.cloud.lb_host_id}"
}

## Setup Firewalls
# Master Firewall
resource "hcloud_firewall" "master-fw" {
  name = "master-fw"
  rule {
    description = "Allow SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTP"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow Kubernetes API"
    direction   = "in"
    protocol    = "tcp"
    port        = "6443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Flannel Overlay Network (VXLAN)"
    direction   = "in"
    protocol    = "udp"
    port        = "8472"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

# Worker Firewall
resource "hcloud_firewall" "worker-fw" {
  name = "worker-fw"
  rule {
    description = "Allow SSH"
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTP"
    direction   = "in"
    protocol    = "tcp"
    port        = "80"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Allow HTTPS"
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "NodePort Services"
    direction   = "in"
    protocol    = "tcp"
    port        = "30000-32767"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
  rule {
    description = "Flannel Overlay Network (VXLAN)"
    direction   = "in"
    protocol    = "udp"
    port        = "8472"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

## Setup Instances
# Master
resource "hcloud_server" "master" {
  image        = var.cloud.image
  location     = var.cloud.location
  name         = var.cloud.master_name
  server_type  = var.cloud.master_type
  firewall_ids = [hcloud_firewall.master-fw.id]
  ssh_keys     = [var.hcloud_ssh_key]
  depends_on = [
    hcloud_network_subnet.subnet,
    hcloud_load_balancer.lb,
    hcloud_load_balancer_network.lb-net,
    hcloud_firewall.master-fw
  ]
  public_net { ipv4_enabled = true }
  network {
    network_id = hcloud_network.net.id
    ip         = "${var.cloud.net_id}${var.cloud.lb_host_id + 1}"
  }
  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.auth_key)
  }
  provisioner "file" {
    source      = "../resources/"
    destination = "/tmp"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/scripts/*.sh",
      "/tmp/scripts/k8s.sh",
      "LB_HOST=$(/tmp/scripts/lb-host.sh ${hcloud_load_balancer.lb.ipv4})",
      "/tmp/scripts/k8s-master.sh ${var.hcloud_token} ${hcloud_network.net.id} ${hcloud_load_balancer.lb.name} $LB_HOST",
      "rm -rf /tmp/scripts"
    ]
  }
  provisioner "local-exec" {
    command = "rm -rfv ./exec/k8s-join.sh && ssh root@${self.ipv4_address} -o StrictHostKeyChecking=no -i ${var.auth_key} 'kubejoin' > ./exec/k8s-join.sh"
    interpreter = [ "bash", "-c" ]
  }
}

# Nodes
resource "hcloud_server" "worker" {
  count        = var.cloud.workers
  image        = var.cloud.image
  location     = var.cloud.location
  server_type  = var.cloud.worker_type
  name         = "${var.cloud.worker_prefix}${count.index + 1}"
  firewall_ids = [hcloud_firewall.worker-fw.id]
  ssh_keys     = [var.hcloud_ssh_key]
  depends_on   = [hcloud_firewall.worker-fw, hcloud_server.master]
  public_net { ipv4_enabled = true }
  network {
    network_id = hcloud_network.net.id
    ip         = "${var.cloud.net_id}${count.index + var.cloud.lb_host_id + 2}"
  }
  connection {
    type        = "ssh"
    user        = "root"
    host        = self.ipv4_address
    private_key = file(var.auth_key)
  }
  provisioner "remote-exec" {
    scripts = [
      "../resources/scripts/k8s.sh",
      "./exec/k8s-join.sh"
    ]
  }
  provisioner "local-exec" {
    command = "ssh root@${hcloud_server.master.ipv4_address} -o StrictHostKeyChecking=no -i ${var.auth_key} '/root/cert-man.sh ${count.index+1}'"
    interpreter = [ "bash", "-c" ]
  }
}
