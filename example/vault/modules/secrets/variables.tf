variable "mount_path" {
  type        = string
  description = "The mount path for the kv secrets engine"
}

variable "description" {
  type        = string
  description = "Description for your kv store"
}

variable "oidc" {
  type = object({
    client_id     = string
    client_secret = string
  })
  sensitive = true
}

variable "gcp" {
  type = object({
    project_id               = string
    client_id                = string
    service_account_username = string
    private_key_id           = string
    private_key              = string
  })
  sensitive = true
  default = {
    project_id               = ""
    client_id                = ""
    service_account_username = ""
    private_key_id           = ""
    private_key              = ""
  }
}
