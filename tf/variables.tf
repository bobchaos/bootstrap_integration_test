# General purpose vars
variable "tags" {
  type        = map
  description = "tags to apply to all relevant assets"
  default     = { dev = true }
}

variable "omnibus_zero_package" {
  type        = string
  description = "Name of the package that will be retrieved from our bucket by the omnibus builder. It must match the name of you package under `policy_artifacts/`"
  default     = "chef_omnibus_builder-0ed5efdccf1ee09126f38215a5f66500c43a6b62eade50f58dfa4c7a55acaf13.tgz"
}

variable "r53_zone_id" {
  type        = string
  description = "A Route53 Zone to use for DNS records"
}

variable "chef_repo_url" {
  type = string
  description = "full address to the Chef repo to clone and build"
  default = "https://github.com/chef/chef.git"
}

variable "chef_repo_branch" {
  type = string
  description = "The Chef branch to build"
  default = "master"
}
