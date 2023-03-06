#!/bin/bash
# Installs k8s on Hetzner Cloud (Ubuntu 22.04)
# Resources:
# - https://community.hetzner.com/tutorials/install-kubernetes-cluster
# - https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
# - https://blog.kay.sh/kubernetes-hetzner-cloud-loadbalancer-nginx-ingress-cert-manager/

# Install transports
apt -y install curl apt-transport-https git wget
# Add google apt key
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
# Add to sources
tee -a /etc/apt/sources.list.d/docker-and-kubernetes.list <<- EOF
    deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable
    deb http://packages.cloud.google.com/apt/ kubernetes-xenial main
EOF

# Install k8s and dependencies
apt update
apt -y install kubelet kubeadm kubectl jq
apt-mark hold kubelet kubeadm kubectl

# Disable swap
swapoff -a
sed -i '/swap/d' /etc/fstab

# Enable kernel modules
cat > /etc/modules-load.d/k8s.conf <<- EOF
br_netfilter

EOF

modprobe overlay
modprobe br_netfilter

# Add settings to sysctl
tee /etc/sysctl.d/kubernetes.conf <<- EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF

# Reload sysctl
sysctl --system

# Install container runtime (Docker CE)
# Add repo and Install packages
apt update
apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
apt update
apt install -y containerd.io docker-ce docker-ce-cli

# Create required directories
mkdir -p /etc/systemd/system/docker.service.d

# Create daemon json config file
tee /etc/docker/daemon.json <<- EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF

tee /etc/systemd/system/kubelet.service.d/20-hcloud.conf <<- EOF
[Service]
Environment="KUBELET_EXTRA_ARGS=--cloud-provider=external"
EOF

# Start and enable docker services
systemctl daemon-reload
systemctl restart docker
systemctl restart kubelet
systemctl enable docker

# Set hostnames | TODO: Automate setting the IP for master
tee -a /etc/hosts <<- EOF
10.98.0.3 k8s-master
EOF

# Install Mirantis CRI - Docker default CRI is not supported by k8s as of v1.20
VER=$(curl -s https://api.github.com/repos/Mirantis/cri-dockerd/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/v//g')
echo "$VER"

wget "https://github.com/Mirantis/cri-dockerd/releases/download/v${VER}/cri-dockerd-${VER}.amd64.tgz"
tar xvf "cri-dockerd-${VER}.amd64.tgz"
rm "cri-dockerd-${VER}.amd64.tgz"

mv cri-dockerd/cri-dockerd /usr/local/bin/
rm -rf "cri-dockerd"
# cri-dockerd --version

# Configure system.d units
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
mv cri-docker.socket cri-docker.service /etc/systemd/system/
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service

# Start & enable services
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket

# Install Helm
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
