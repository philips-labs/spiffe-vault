# SPIFFE Vault

Integrates [SPIFFE][spiffe] SVID authentication with [Hashicorp Vault][hashivault] to retrieve a `VAULT_TOKEN`.

## Example usecases

- Read secrets from Hashicorp Vault [Hashicorp Vault][hashivault] without providing a secret to authenticate against [Hashicorp Vault][hashivault]. Instead we will be using a [SPIFFE][spiffe] SVID to authenticate ourself against [Hashicorp Vault][hashivault].

- Perform secretless/keyless code signing by utilizing the [Hashicorp Vault Transit engine](https://www.vaultproject.io/docs/secrets/transit) as a software defined HSM. This resolves the issue of having signing keys on a local machine as well resolves the issue of managing secrets to access the signing keys. Again we utilize the [SPIFFE][spiffe] SVID to authenticate against Hashicorp Vault.

[hashivault]: https://vaultproject.org "hashicorp Vault"
[spiffe]: https://spiffe.io "SPIFFE"
