resource "vault_mount" "transit" {
  path                      = var.mount_path
  type                      = "transit"
  description               = var.description
  default_lease_ttl_seconds = 600
  max_lease_ttl_seconds     = 3600
}

resource "vault_transit_secret_backend_key" "code_signing_dev" {
  backend = vault_mount.transit.path
  name    = var.key.name
  type    = var.key.type
}

data "vault_policy_document" "code_signing" {
  rule {
    path         = "${vault_mount.transit.path}/keys"
    capabilities = ["list"]
    description  = "Allow listing available keys"
  }

  rule {
    path         = "${vault_mount.transit.path}/keys/${vault_transit_secret_backend_key.code_signing_dev.name}"
    capabilities = ["read"]
    description  = "Allow reading key details"
  }

  rule {
    path         = "${vault_mount.transit.path}/hmac/${vault_transit_secret_backend_key.code_signing_dev.name}/*"
    capabilities = ["update"]
    description  = "Allow creating hmacs"
  }

  rule {
    path         = "${vault_mount.transit.path}/sign/${vault_transit_secret_backend_key.code_signing_dev.name}/*"
    capabilities = ["update"]
    description  = "Allow creating signatures"
  }

  rule {
    path         = "${vault_mount.transit.path}/sign/${vault_transit_secret_backend_key.code_signing_dev.name}/sha1"
    capabilities = ["deny"]
    description  = "Disable insecure SHA1"
  }

  rule {
    path         = "${vault_mount.transit.path}/verify/${vault_transit_secret_backend_key.code_signing_dev.name}/*"
    capabilities = ["update"]
    description  = "Allow verifying signatures and hmacs"
  }

  rule {
    path         = "${vault_mount.transit.path}/verify/${vault_transit_secret_backend_key.code_signing_dev.name}/sha1"
    capabilities = ["deny"]
    description  = "Disable insecure SHA1"
  }
}

resource "vault_policy" "code_signing" {
  name   = var.policy
  policy = data.vault_policy_document.code_signing.hcl
}
