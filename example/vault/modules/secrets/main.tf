resource "vault_mount" "kv_v2" {
  path        = var.mount_path
  type        = "kv-v2"
  description = var.description
}

data "vault_policy_document" "fpl" {
  rule {
    path         = "${var.mount_path}/*"
    capabilities = ["read", "list"]
    description  = "Allow to access the fhir patient list secrets"
  }
}

resource "vault_policy" "fpl" {
  name   = var.mount_path
  policy = data.vault_policy_document.fpl.hcl
}

resource "vault_generic_secret" "oidc" {
  path = "${vault_mount.kv_v2.path}/oidc"

  data_json = <<EOT
{
  "clientId": "${var.oidc.client_id}",
  "clientSecret": "${var.oidc.client_secret}"
}
EOT
}

resource "vault_generic_secret" "gcp" {
  path = "${vault_mount.kv_v2.path}/gcp"

  data_json = <<EOT
{
  "projectId": "${var.gcp.project_id}",
  "clientId": "${var.gcp.client_id}",
  "serviceAccountUsername": "${var.gcp.service_account_username}",
  "privateKeyId": "${var.gcp.private_key_id}",
  "privateKey": "${replace(var.gcp.private_key, "\n", "\\n")}"
}
EOT
}
