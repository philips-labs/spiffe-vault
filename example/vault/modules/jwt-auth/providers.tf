terraform {
  required_version = ">= 0.14.5"
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = ">=2.21.0"
    }
  }
}
