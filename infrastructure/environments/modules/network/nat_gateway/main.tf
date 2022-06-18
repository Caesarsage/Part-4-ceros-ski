/**
* A NAT Gateway that lives in our public subnet and provides an interface
* between our private subnets and the public internet.  It allows traffic to
* exit our private subnets, but prevents traffic from entering them.
*/

variable "environment" {}
variable "public_subnets" {}

# # ELASTIC IP 
module "elastic_ip_module" {
  source      = "../elastic_ip"
  environment = var.environment
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = module.elastic_ip_module.elastic_ip_id
  subnet_id     = element(var.public_subnets.*.id, 0)

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a"
    Resource    = "modules.availability_zone.aws_nat_gateway.nat_gateway"
  }
}

output "nat_gateway_id" {
  value = aws_nat_gateway.nat_gateway.id
}
