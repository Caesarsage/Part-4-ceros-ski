output "vpc_id" {
  value = module.network_module.vpc_id
}
output "private_subnets" {
  value = module.network_module.private_subnets
}
output "public_subnets" {
  value = module.network_module.public_subnets
}