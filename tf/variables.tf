# General purpose vars
variable "tags" {
  type        = map
  description = "tags to apply to all relevant assets"
  default     = { dev = true }
}

variable "omnibus_zero_package" {
  type        = string
  description = "Name of the package that will be retrieved from our bucket by the omnibus builder. It must match the name of you package under `policy_artifacts/`"
  default     = "chef_omnibus_builder-8a6d4e30097523e0897e7fd96c8b07eb2ca7289c5df57d2b219f888238bf2d6c.tgz"
}

variable "r53_zone_id" {
  type        = string
  description = "A Route53 Zone to use for DNS records"
}
