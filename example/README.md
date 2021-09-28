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
helm repo add traefik https://helm.traefik.io/traefik
helm repo update
```

### Install

Now we will deploy the Helm charts to our Kubernetes cluster.

```bash
helm -n my-spire install spire philips-labs/spire --create-namespace -f k8s/spire-values.yaml
helm -n my-traefik install traefik traefik/traefik --create-namespace -f k8s/traefik-values.yaml
helm -n my-vault install vault hashicorp/vault --create-namespace -f k8s/vault-values.yaml
```

### Provision Vault

Once the core infrastructure is deployed we will have to provision the authentication method to [Vault][hashi-vault]. Terraform will also provision a transit engine which I use in the example below. Also note the Vault policy prevents you from doing any other operations then allowed by the policy. Doing so enables us to have finegrained access to different resources in Vault.

```bash
cd vault/environments/local
cp secrets.auto.tfvars.template secrets.auto.tfvars
# fill out the secrets you want to provision into vault
terraform init
terraform plan
terraform apply -auto-approve
```

### Deploy spiffe-vault workload

Within kubernetes our Spire Helm chart also deploys the [spire-k8s-workload-registrar][spire-k8s-workload-registrar]. This Spire component takes care of registering workloads/pods with the Spire server. Once a workload is registered with the Spire Server it will be given a SPIFFE ID.

```bash
helm -n my-app install my-app ../charts/spiffe-vault --create-namespace -f k8s/spiffe-vault.yaml
```

### play with spiffe-vault

Using our `spiffe-vault` workload, which at this stage has a SPIFFE ID, we can now authenticate to Hashicorp Vault. Hashicorp Vault was configured to allow authentication via a JWT token with a given subject matching the SPIFFE ID.

The flow below will perform the following steps.

1. Open a Shell to the `spiffe-vault` container in kubernetes.
2. Configure the VAULT_ADDR to point to our Vault deployment.
3. Use the `spiffe-vault` cli-tool to perform the authentication to Vault using a Spire JWT and then export the VAULT_TOKEN in our current shell.
4. Interact with the Vault using the Vault cli.

```bash
$ kubectl exec -n my-app -i -t \
    $(kubectl -n my-app get pods -l app.kubernetes.io/name=spiffe-vault -o jsonpath="{.items[0].metadata.name}") \
    -c spiffe-vault -- sh
$ export VAULT_ADDR=http://vault-internal.my-vault:8200
$ eval "$(./spiffe-vault auth -role local)"
$ vault list transit/keys
Keys
----
cosign
$ vault read transit/keys/cosign
Key                       Value
---                       -----
allow_plaintext_backup    false
deletion_allowed          false
derived                   false
exportable                false
keys                      map[1:map[creation_time:2021-09-27T12:28:54.878899344Z name:P-256 public_key:-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAERyHSkgCB+QrOLQEFU3W16Ir4pkir
YXNU+PgP2vEce1Klq0LfG792iLCNIODa/Jt3fw4Uu9dS7KVqM8XNsAlU1A==
-----END PUBLIC KEY-----
]]
latest_version            1
min_available_version     0
min_decryption_version    1
min_encryption_version    0
name                      cosign
supports_decryption       false
supports_derivation       false
supports_encryption       false
supports_signing          true
type                      ecdsa-p256
```

Please note that we configured vault to have a token lifetime of only 600 seconds. Before the token expires you will have to renew the token or retrieve a new one using `spiffe-vault`.

A practical usecase for using the transit engine is for example in combination with [Cosign][cosign]. We can use it to create a signature without the need to download a signing key on our local system. Assuming you would have [Cosign][cosign] installed following flow would be possible with this example setup.

```bash
$ kubectl exec -n my-app -i -t \
    $(kubectl -n my-app get pods -l app.kubernetes.io/name=spiffe-vault -o jsonpath="{.items[0].metadata.name}") \
    -c spiffe-vault -- sh
$ export VAULT_ADDR=http://vault-internal.my-vault:8200
$ eval "$(./spiffe-vault auth -role local)"
$ cosign sign -key hashivault://cosign philipssoftware/spiffe-vault:latest
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
[spire-k8s-workload-registrar]: https://github.com/spiffe/spire/tree/main/support/k8s/k8s-workload-registrar "The SPIRE Kubernetes Workload Registrar implements a Kubernetes ValidatingAdmissionWebhook that facilitates automatic workload registration within Kubernetes."
[cosign]: https://github.com/sigstore/cosign "Container Signing, Verification and Storage in an OCI registry."
