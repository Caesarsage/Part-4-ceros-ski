output "private_subnets" {
  value = module.subnet_private_module.private_subnets
}

output "public_subnets" {
  value = module.subnet_public_module.public_subnets
}
output "vpc_id" {
  value = module.vpc_module.vpc_id
}