resource "vault_jwt_auth_backend" "spire_oidc" {
  description        = "JWT auth using Spire OIDC"
  path               = "jwt"
  oidc_discovery_url = var.oidc_discovery_url
  default_role       = ""
}

resource "vault_jwt_auth_backend_role" "spire_oidc" {
  for_each        = zipmap(range(length(var.roles)), var.roles)
  backend         = vault_jwt_auth_backend.spire_oidc.path
  role_name       = each.value.name
  token_policies  = ["default", each.value.policy]
  token_ttl       = 60
  bound_audiences = ["TESTING"]
  bound_subject   = each.value.subject
  user_claim      = "sub"
  role_type       = "jwt"
}
