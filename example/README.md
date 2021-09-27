# Example

In this example directory we have an example setup on how to deploy and setup [Hashicorp Vault][hashi-vault] in combination with [Spire][spire] in a [Kubernetes][kubernetes] cluster. Using this infrastructure we are able to deploy our `spiffe-vault` workload that allows us to interact with [Hashicorp Vault][hashi-vault] using [SPIFFE][spiffe] SVIDS.

## Prerequisites

- [Kubernetes][kubernetes] cluster ([Docker Desktop][docker-desktop], or any cloud provider hosted distribution like [EKS][eks], [AKS][aks] or [GKE][gke].)
- [Helm][helm]
- [Terraform][terraform]

## Setup the example

In the `k8s` folder you will find the Kubernetes deployments to deploy Spire and Hashicorp Vault.

In the `vault` folder you will find the Terraform scripts to provision vault with some initial configuration.

To get started we will first have to deploy the core infrastructure to run our components.

### Add Helm repositories

We make use of some existing Helm charts. To do so we have to add these repositories.

```bash
helm repo add philips-labs https://philips-labs.github.io/helm-charts/
helm repo add hashicorp https://helm.releases.hashicorp.com
helm repo update
```

### Install

Now we will deploy the Helm charts to our Kubernetes cluster.

```bash
helm -n my-spire install spire philips-labs/spire --create-namespace -f k8s/spire-values.yaml
helm -n my-vault install vault hashicorp/vault --create-namespace -f k8s/vault-values.yaml
```

### Provision Vault

Once the core infrastructure is deployed we will have to provision the authentication method to [Vault][hashi-vault].

```bash
cd vault/environments/local
cp secrets.auto.tfvars.template secrets.auto.tfvars
# fill out the secrets you want to provision into vault
terraform init
terraform plan
terraform apply -auto-approve
```

### Deploy spiffe-vault workload

```bash
helm -n my-app install my-app ../charts/spiffe-vault --create-namespace -f k8s/spiffe-vault.yaml
```

### play with spiffe-vault

```bash
$ kubectl exec -n my-app -i -t \
    $(kubectl -n my-app get pods -l app.kubernetes.io/name=spiffe-vault -o jsonpath="{.items[0].metadata.name}") \
    -c spiffe-vault -- sh
$ export VAULT_ADDR=http://vault-internal.my-vault:8200
$ ./spiffe-vault auth -role local
```

[kubernetes]: https://kubernetes.io "Production-Grade Container Orchestration"
[hashi-vault]: https://vaultproject.io "Manage Secrets and Protect Sensitive Data"
[spiffe]: https://spiffe.io "A universal identity control plane for distributed systems"
[spire]: https://spiffe.io/downloads/ "Implementation of the SPIFFE protocol"
[terraform]: https://terraform.io "Open-source infrastructure as code software tool"
[helm]: https://helm.sh "The package manager for Kubernetes"
[docker-desktop]: https://www.docker.com/products/docker-desktop "The fastest way to containerize applications on your desktop"
[eks]: https://aws.amazon.com/eks/ "Amazon Elastic Kubernetes Service"
[aks]: https://azure.microsoft.com/en-us/services/kubernetes-service/ "Azure Kubernetes Service"
[gke]: https://cloud.google.com/kubernetes-engine "Google Kubernetes Engine"
