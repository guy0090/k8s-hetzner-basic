#!/bin/bash
# - https://community.hetzner.com/tutorials/install-kubernetes-cluster
# - https://computingforgeeks.com/deploy-kubernetes-cluster-on-ubuntu-with-kubeadm/
# - https://blog.kay.sh/kubernetes-hetzner-cloud-loadbalancer-nginx-ingress-cert-manager/

# Enable kubelet
sudo systemctl enable kubelet

## Bootstrap the cluster without DNS endpoint
# 10.244.0.0/16 is the default Flannel network
kubeadm init \
    --pod-network-cidr=10.244.0.0/16 \
    --apiserver-advertise-address=0.0.0.0 \
    --upload-certs \
    --control-plane-endpoint=k8s-master \
    --cri-socket unix:///run/cri-dockerd.sock

# Copy the kubeconfig to the local user
mkdir -p "$HOME/.kube"
sudo cp -i /etc/kubernetes/admin.conf "$HOME/.kube/config"
sudo chown "$(id -u):$(id -g)" "$HOME/.kube/config"

# Flannel CNI
# Uses type VXLAN - Make sure port (UDP) 8472 is open on all nodes firewalls
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Cloud config
kubectl -n kube-system create secret generic hcloud \
    --from-literal=token="$1" \
    --from-literal=network="$2"

# Hetnzer Cloud Controller
kubectl -n kube-system apply -f https://github.com/hetznercloud/hcloud-cloud-controller-manager/releases/download/v1.13.2/ccm-networks.yaml

# Ingress controller as DaemonSet
wget -q https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.5.1/deploy/static/provider/cloud/deploy.yaml -O /tmp/nginx.yaml

sed -i -e "s/kind: Deployment/kind: DaemonSet/g" /tmp/nginx.yaml
sed -i -e '/^kind: ConfigMap.*/i  \ \ compute-full-forwarded-for: \"true\"\n \ use-forwarded-headers: \"true\"\n \ use-proxy-protocol: \"true\"' /tmp/nginx.yaml

kubectl apply -f /tmp/nginx.yaml

# Connect Load Balancer to Ingress Controller
kubectl -n ingress-nginx annotate services ingress-nginx-controller \
    load-balancer.hetzner.cloud/name="$3" \
    load-balancer.hetzner.cloud/location="nbg1" \
    load-balancer.hetzner.cloud/use-private-ip="true" \
    load-balancer.hetzner.cloud/uses-proxyprotocol="true" \
    load-balancer.hetzner.cloud/hostname="$4"

# Cleanup temporary files
rm /tmp/nginx.yaml
mv /tmp/manifests ~/

# Make join script executable
mv /tmp/scripts/k8s-join.sh /usr/local/bin/kubejoin
chmod +x /usr/local/bin/kubejoin

# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Move cert-man install script for later use
mv /tmp/scripts/cert-man.sh ~/