variable "roles" {
  type = list(object({
    name    = string
    subject = string
    policy  = string
  }))
  description = "The name, subject and policy per role."
}

variable "oidc_discovery_url" {
  type        = string
  description = "The discovery url of the oidc service"
  default     = "http://spire-oidc.spire"
}
