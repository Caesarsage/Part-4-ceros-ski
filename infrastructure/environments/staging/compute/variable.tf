variable "environment" {
  type        = string
  default     = "production"
  description = "The name of the environment we'd like to launch."
}
variable "aws_credentials_file" {
  type = string
}
variable "aws_profile" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "repository_url" {}
variable "public_key" {}
variable "availability_zones" {}
variable "cidr_block" {}
variable "private_subnets_count" {}
variable "public_subnets_count" {}