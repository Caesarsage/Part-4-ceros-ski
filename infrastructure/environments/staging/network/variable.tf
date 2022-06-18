variable "environment" {
  type        = string
  default     = "production"
  description = "The name of the environment we'd like to launch."
}
variable "cidr_block" {}
variable "aws_credentials_file" {
  type = string
}
variable "aws_profile" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "availability_zones" {}
variable "private_subnets_count" {}
variable "public_subnets_count" {}