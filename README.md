# Hetzner k8s Cluster

The result of me spending hours reading outdated k8s guides:

Create a simple 1-master/n-worker (default 2) Kubernetes cluster on Hetzner Cloud with
nginx-ingress connected to Hetzner Cloud Load Balancer and cert-manager with Let's Encrypt Issuer.

This is by **no means** a production ready setup and is primarily aimed at learning the basics of k8s
and Terraform.

## Resources
The following is *most* of what I used:

### Guides
- [This blog](https://blog.kay.sh/kubernetes-hetzner-cloud-loadbalancer-nginx-ingress-cert-manager/)
- [Networking (Outdated)](https://github.com/coreos/coreos-kubernetes/blob/master/Documentation/kubernetes-networking.md#port-allocation)
- [kubectl cheat sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
- [k8s the hard way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Hetzner k8s Setup](https://community.hetzner.com/tutorials/install-kubernetes-cluster/)

### Tools
- [Terraform](https://developer.hashicorp.com/terraform/language/resources)
- [Helm](https://helm.sh/)
- [hcloud](https://github.com/hetznercloud/cli)

### Used Kubernetes Addons
- [Flannel](https://github.com/flannel-io/flannel#flannel)
- [cert-manager](https://cert-manager.io/)
- [NGINX  Ingress](https://docs.nginx.com/nginx-ingress-controller/)
- [Mirantis CRI](https://github.com/Mirantis/cri-dockerd#motivation)
---
## Requirements

To manage your Hetzner Cloud install [hcloud cli](https://github.com/hetznercloud/cli):
- Windows: `scoop install hcloud`
- Linux/MacOS: `brew install hcloud`

Bootstrapping the hcloud resources is handled by [Terraform](https://developer.hashicorp.com/terraform):
- Windows: `scoop install terraform`
- Linux/MacOS: `brew install terraform`

## Setup
### Generate an SSH key for Hetzner Cloud:
To access hcloud and manage your resources, you'll need to add an SSH key
to your project and generate an API token that we can use during the setup process.

```bash
# Generate the key (accept any prompts, comment/password is optional)
ssh-keygen -t ed25519 -C "<comment>"

cat ~/.ssh/id_ed25519.pub # Replace with your key location if you changed it
```

Add your SSH key to Hetzner Cloud:
- Visit https://console.hetzner.cloud/projects/xxxx/security/sshkeys
- "xxxx" is replaced by your project ID

Generate a Hetzner Cloud project API token:
- Visit https://console.hetzner.cloud/projects/xxxx/security/tokens
- "xxxx" is replaced by your project ID

Add and Activate hcloud Context (will prompt for API token):
```bash
hcloud context create YOUR_CONTEXT_NAME # Can be anything you like
```

### Continue with your preferred setup method: [Terraform](#terraform) | [The Hard Way](#manual)

### Terraform

Create and setup your .tfvars file:
```bash
cd terraform
cp hcloud.example.tfvars hcloud.tfvars
vi hcloud.tfvars
```

Initialize Terraform:
```bash
terraform init
```

Create and Apply Terraform Plan (will take a few minutes):
```bash
# Used to bootstrap our cloud
terraform plan -var-file="./hcloud.tfvars" -out create

# This will create all our servers and connect them
terraform apply create
```
### Done!

Once it finishes creating, check the RDNS* of your load balancer
in your browser. You should see "Hello, World!" (ignore the insecure site warning if using `staging` Issuer)
- *RDNS is `static.000.000.000.000.clients.your-server.de` where `000.000.000.000` is the public IPv4 reversed
  i.e.: if the IPv4 is `167.233.8.37`, the RDNS is `static.37.8.233.167.clients.your-server.de`
- Also found in hcloud Console: ![rdns](https://i.imgur.com/SSnKsdF.png)

### Cleanup

Once you're done you can delete the entire cloud with a "destroy" plan:
```bash
# Used to tear down what we created all at once
terraform plan -destroy -var-file="./hcloud.tfvars" -out destroy
terraform apply destroy
```

### Manual
TODO
- Check the `resources/scripts` folder for used scripts
- Check the `terraform/` folder for Terraform configs
