
/**
* A NAT Gateway that lives in our public subnet and provides an interface
* between our private subnets and the public internet.  It allows traffic to
* exit our private subnets, but prevents traffic from entering them.
*/


resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = var.elastic_ip_id
  subnet_id     = element(var.public_subnets.*.id, 0)

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a"
    Resource    = "modules.availability_zone.aws_nat_gateway.nat_gateway"
  }
}

/******************************************************************************
* Private Subnet 
*******************************************************************************/

/** 
* A private subnet for pieces of the infrastructure that we don't want to be
* directly exposed to the public internet.  Infrastructure launched into this
* subnet will not have public IP addresses, and can access the public internet
* only through the route to the NAT Gateway.
*/
resource "aws_subnet" "private_subnets" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = false
  count                   = var.private_subnets_count

  tags = {
    Name        = "ceros-ski-${count.index * 2}.0_${element(var.availability_zones, count.index)}"
    Application = "ceros-ski"
    Environment = var.environment
    Resource    = "modules.availability_zone.aws_subnet.private_subnet"
  }
}

/**
* A route table for the private subnet.
*/
resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a-private"
    Resource    = "modules.availability_zone.aws_route_table.private_route_table"
  }
}

/**
* A route from the private route table out to the internet through the NAT  
* Gateway.
*/

resource "aws_route_table" "private_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

/**
* Associate the private route table with the private subnet.
*/
resource "aws_route_table_association" "private" {
  count          = var.private_subnets_count
  subnet_id      = element(aws_subnet.private_subnets.*.id, count.index)
  route_table_id = aws_route_table.private_rt.id
}