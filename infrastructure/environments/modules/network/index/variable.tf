variable "environment" {
  type        = string
  default     = "production"
  description = "The name of the environment we'd like to launch."
}
variable "cidr_block" {}
variable "availability_zones" {}
variable "private_subnets_count" {}
variable "public_subnets_count" {}