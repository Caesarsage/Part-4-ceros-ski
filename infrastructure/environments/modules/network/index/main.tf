# VPC

module "vpc_module" {
  source      = "../vpc"
  environment = var.environment
}


# INTERNET GATEWAY
module "internet_gateway_module" {
  source      = "../internet_gateway"
  vpc_id      = module.vpc_module.vpc_id
  environment = var.environment
}



# # PUBLIC SUBNET
module "subnet_public_module" {
  source              = "../subnets/public"
  vpc_id              = module.vpc_module.vpc_id
  vpc_cidr_block      = module.vpc_module.vpc_cidr_block
  internet_gateway_id = module.internet_gateway_module.internet_gateway_id

  availability_zones   = var.availability_zones
  environment          = var.environment
  public_subnets_count = var.public_subnets_count
}

module "nat_gateway_module" {
  source                = "../nat_gateway"
  public_subnets = module.subnet_public_module.public_subnets
  environment = var.environment
}

# # PRIVATE SUBNET
module "subnet_private_module" {
  source                = "../subnets/private"
  vpc_id                = module.vpc_module.vpc_id
  vpc_cidr_block        = module.vpc_module.vpc_cidr_block
  nat_gateway_id = module.nat_gateway_module.nat_gateway_id

  availability_zones    = var.availability_zones
  environment           = var.environment
  private_subnets_count = var.private_subnets_count
}