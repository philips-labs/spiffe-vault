locals {
  environment = "local"
}

module "transit_engine" {
  source = "../../modules/transit"

  mount_path  = "transit"
  description = "Used for encryption and code-signing purposes"

  key = {
    name = "cosign"
    type = "ecdsa-p256"
  }
  policy = "${local.environment}-signing"
}

module "jwt_auth" {
  source = "../../modules/jwt-auth"

  roles = [
    {
      name    = local.environment,
      subject = "spiffe://dev.localhost/ns/my-app/sa/my-app",
      policy  = "${local.environment}-signing"
    }
  ]
}
