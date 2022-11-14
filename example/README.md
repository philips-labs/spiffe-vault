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

> :warning: Add `vault.localhost` to your hosts file (`/etc/hosts`).

Once the core infrastructure is deployed we will have to provision the authentication method to [Vault][hashi-vault]. Terraform will also provision a transit engine which I use in the example below. Also note the Vault policy prevents you from doing any other operations then allowed by the policy. Doing so enables us to have finegrained access to different resources in Vault.

```bash
cd vault/environments/local
terraform init
terraform plan
terraform apply -auto-approve
```

### Deploy spiffe-vault workload

Within kubernetes our Spire Helm chart also deploys the [spire-k8s-workload-registrar][spire-k8s-workload-registrar]. This Spire component takes care of registering workloads/pods with the Spire server. Once a workload is registered with the Spire Server it will be given a SPIFFE ID.

In `k8s/spiffe-vault.yaml` we defined we want to use the `philipssoftware/spiffe-vault-cosign` image that adds the [Cosign][cosign] binary in the image as well. So we can also play with cosign later in this example.

Let's build this custom build now and then deploy our workload to Kubernetes.

```bash
docker build -t philipssoftware/spiffe-vault-cosign:latest spiffe-vault-cosign
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
$ eval "$(spiffe-vault auth -role local)"
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

A practical usecase for using the transit engine is for example in combination with [Cosign][cosign]. We can use it to create a signature without the need to download a signing key on our local system. We used a custom build of our `spiffe-vault` image when deploying our app including [Cosign][cosign]. In the following workflow you might want to try the following with your personal dockerhub account, so replace my username with your own.

```bash
$ kubectl exec -n my-app -i -t \
    $(kubectl -n my-app get pods -l app.kubernetes.io/name=spiffe-vault -o jsonpath="{.items[0].metadata.name}") \
    -c spiffe-vault -- sh
$ export VAULT_ADDR=http://vault-internal.my-vault:8200
$ docker login
Login with your Docker ID to push and pull images from Docker Hub. If you don't have a Docker ID, head over to https://hub.docker.com to create one.
Username: marcofranssen
Password:
WARNING! Your password will be stored unencrypted in /root/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
$ docker pull busybox
$ docker tag busybox marcofranssen/busybox:latest
$ docker push marcofranssen/busybox:latest
Using default tag: latest
The push refers to repository [docker.io/marcofranssen/busybox]
cfd97936a580: Mounted from library/busybox
latest: digest: sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b size: 527
$ eval "$(spiffe-vault auth -role local)"
$ cosign sign -key hashivault://cosign marcofranssen/busybox:latest
Pushing signature to: index.docker.io/marcofranssen/busybox:sha256-febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b.sig
$ cosign verify -key hashivault://cosign marcofranssen/busybox:latest

Verification for marcofranssen/busybox:latest --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.

[{"critical":{"identity":{"docker-reference":"index.docker.io/marcofranssen/busybox"},"image":{"docker-manifest-digest":"sha256:febcf61cd6e1ac9628f6ac14fa40836d16f3c6ddef3b303ff0321606e55ddd0b"},"type":"cosign container image signature"},"optional":null}]
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
