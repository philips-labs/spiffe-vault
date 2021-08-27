variable "mount_path" {
  type        = string
  description = "The mount path for the transit engine"
  default     = "transit"
}

variable "description" {
  type        = string
  description = "Description for the transit engine"
}

variable "key" {
  type = object({
    name = string
    type = string
  })
}

variable "policy" {
  type        = string
  description = "Policy to apply on the transit engine"
}
