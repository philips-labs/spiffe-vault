terraform {
  required_version = ">= 1.0.8"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 5.0.0"
    }
  }
}
