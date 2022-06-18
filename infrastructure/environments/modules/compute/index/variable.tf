variable "environment" {
  type        = string
  default     = "production"
  description = "The name of the environment we'd like to launch."
}
variable "repository_url" {}
variable "public_key" {}
variable "availability_zones" {}
variable "cidr_block" {}
variable "private_subnets_count" {}
variable "public_subnets_count" {}