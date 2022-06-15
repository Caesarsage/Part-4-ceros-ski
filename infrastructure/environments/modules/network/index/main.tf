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

# # ELASTIC IP 
module "elastic_ip_module" {
  source      = "../elastic_ip"
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

# # PRIVATE SUBNET
module "subnet_private_module" {
  source                = "../subnets/private"
  vpc_id                = module.vpc_module.vpc_id
  vpc_cidr_block        = module.vpc_module.vpc_cidr_block
  availability_zones    = var.availability_zones
  elastic_ip_id         = module.elastic_ip_module.elastic_ip_id
  environment           = var.environment
  private_subnets_count = var.private_subnets_count
  public_subnets        = module.subnet_public_module.public_subnets
}