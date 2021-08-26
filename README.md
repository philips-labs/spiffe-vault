# SPIFFE Vault

Integrates [SPIFFE][spiffe] SVID authentication with [Hashicorp Vault][hashivault] to retrieve a `VAULT_TOKEN`.

## Example usecases

- Read secrets from Hashicorp Vault [Hashicorp Vault][hashivault] without providing a secret to authenticate against [Hashicorp Vault][hashivault]. Instead we will be using a [SPIFFE][spiffe] SVID to authenticate ourself against [Hashicorp Vault][hashivault].

- Perform secretless/keyless code signing by utilizing the [Hashicorp Vault Transit engine](https://www.vaultproject.io/docs/secrets/transit) as a software defined HSM. This resolves the issue of having signing keys on a local machine as well resolves the issue of managing secrets to access the signing keys. Again we utilize the [SPIFFE][spiffe] SVID to authenticate against Hashicorp Vault.

[hashivault]: https://vaultproject.org "hashicorp Vault"
[spiffe]: https://spiffe.io "SPIFFE"

## Compile

```bash
make build
```

## Use

### Basic

```bash
$ export VAULT_ADDR=http://localhost:8200
$ bin/spiffe-vault auth -role my-role
# Export following environment variable to authenticate to Hashicorp Vault
export VAULT_TOKEN=s.IK1LBrCGXFQDAgawmhNLbcDH
```

### Advanced

Depending on the shell you are using you can automatically export the variable.

<details>
  <summary>bash</summary>

```bash
$ export VAULT_ADDR=http://localhost:8200
$ echo "$(bin/spiffe-vault auth -role my-role)" > /tmp/spiffe-vault
$ source /tmp/spiffe-vault
$ vault kv get secrets/my-key
====== Metadata ======
Key              Value
---              -----
created_time     2021-08-24T08:20:54.925866504Z
deletion_time    n/a
destroyed        false
version          1

============= Data =============
Key                       Value
---                       -----
username                  marco
password                  Supers3cr3t!
$ vault token lookup
Key                 Value
---                 -----
accessor            rwpXIHXzbVIMN2TL25Lfssef
creation_time       1629970184
creation_ttl        1m
display_name        jwt-spiffe://dev.localhost/ns/my-app/sa/my-app-backend
entity_id           8904661e-5a9f-3af5-c269-257e8a0a31d0
expire_time         2021-08-26T09:30:44.424072877Z
explicit_max_ttl    0s
id                  s.eOdhqe1hVV0OPS7M0TSeEqjG
issue_time          2021-08-26T09:29:44.424078028Z
meta                map[role:my-role]
num_uses            0
orphan              true
path                auth/jwt/login
policies            [default my-role]
renewable           true
ttl                 13s
type                service
$ vault token renew
Key                  Value
---                  -----
token                s.f1mFvr0TdEuvmfcZT0jBLCc5
token_accessor       vxginlb81XMEIPefLpRz1P24
token_duration       1m
token_renewable      true
token_policies       ["default" "my-role"]
identity_policies    []
policies             ["default" "my-role"]
token_meta_role      my-role
$ vault token lookup
Key                  Value
---                  -----
accessor             vxginlb81XMEIPefLpRz1P24
creation_time        1629970320
creation_ttl         1m
display_name         jwt-spiffe://dev.localhost/ns/my-app/sa/my-app-backend
entity_id            8904661e-5a9f-3af5-c269-257e8a0a31d0
expire_time          2021-08-26T09:33:53.57444787Z
explicit_max_ttl     0s
id                   s.f1mFvr0TdEuvmfcZT0jBLCc5
issue_time           2021-08-26T09:32:00.135787193Z
last_renewal         2021-08-26T09:32:53.574447972Z
last_renewal_time    1629970373
meta                 map[role:my-role]
num_uses             0
orphan               true
path                 auth/jwt/login
policies             [default my-role]
renewable            true
ttl                  56s
type                 service
```

</details>

<details>
  <summary>zsh</summary>

```zsh
$ export VAULT_ADDR=http://localhost:8200
$ source <(bin/spiffe-vault auth -role my-role)
$ vault kv get secrets/my-key
====== Metadata ======
Key              Value
---              -----
created_time     2021-08-24T08:20:54.925866504Z
deletion_time    n/a
destroyed        false
version          1

============= Data =============
Key                       Value
---                       -----
username                  marco
password                  Supers3cr3t!
$ vault token lookup
Key                 Value
---                 -----
accessor            rwpXIHXzbVIMN2TL25Lfssef
creation_time       1629970184
creation_ttl        1m
display_name        jwt-spiffe://dev.localhost/ns/my-app/sa/my-app-backend
entity_id           8904661e-5a9f-3af5-c269-257e8a0a31d0
expire_time         2021-08-26T09:30:44.424072877Z
explicit_max_ttl    0s
id                  s.eOdhqe1hVV0OPS7M0TSeEqjG
issue_time          2021-08-26T09:29:44.424078028Z
meta                map[role:my-role]
num_uses            0
orphan              true
path                auth/jwt/login
policies            [default my-role]
renewable           true
ttl                 13s
type                service
$ vault token renew
Key                  Value
---                  -----
token                s.f1mFvr0TdEuvmfcZT0jBLCc5
token_accessor       vxginlb81XMEIPefLpRz1P24
token_duration       1m
token_renewable      true
token_policies       ["default" "my-role"]
identity_policies    []
policies             ["default" "my-role"]
token_meta_role      my-role
$ vault token lookup
Key                  Value
---                  -----
accessor             vxginlb81XMEIPefLpRz1P24
creation_time        1629970320
creation_ttl         1m
display_name         jwt-spiffe://dev.localhost/ns/my-app/sa/my-app-backend
entity_id            8904661e-5a9f-3af5-c269-257e8a0a31d0
expire_time          2021-08-26T09:33:53.57444787Z
explicit_max_ttl     0s
id                   s.f1mFvr0TdEuvmfcZT0jBLCc5
issue_time           2021-08-26T09:32:00.135787193Z
last_renewal         2021-08-26T09:32:53.574447972Z
last_renewal_time    1629970373
meta                 map[role:my-role]
num_uses             0
orphan               true
path                 auth/jwt/login
policies             [default my-role]
renewable            true
ttl                  56s
type                 service
```

</details>
