
/******************************************************************************
* Public Subnet 
*******************************************************************************/

/**
* A public subnet with in our VPC that we can launch resources into that we
* want to be auto-assigned public ip addresses.  These resources will be
* exposed to the public internet, with public IPs, by default.  They don't need
* to go through, and aren't shielded by, the NAT Gateway.
*/
resource "aws_subnet" "public_subnets" {
  vpc_id                  = var.vpc_id
  cidr_block              = cidrsubnet(var.vpc_cidr_block, 8, 2 + count.index)
  availability_zone       = element(var.availability_zones, count.index)
  map_public_ip_on_launch = true
  count                   = var.public_subnets_count
  tags = {
    Name        = "ceros-ski-${count.index * 2 + 1}.0_${element(var.availability_zones, count.index)}"
    Application = "ceros-ski"
    Resource    = "modules.availability_zone.aws_subnet.public_subnet"
    Environment = var.environment
  }
}
/**
* A NAT Gateway that lives in our public subnet and provides an interface
* between our private subnets and the public internet.  It allows traffic to
* exit our private subnets, but prevents traffic from entering them.
*/

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = var.elastic_ip_id
  subnet_id     = element(aws_subnet.public_subnets.*.id, 0)

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a"
    Resource    = "modules.availability_zone.aws_nat_gateway.nat_gateway"
  }
}

/**
* A route table for our public subnet.
*/
resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  tags = {
    Application = "ceros-ski"
    Environment = var.environment
    Name        = "ceros-ski-${var.environment}-us-east-1a-public"
    Resource    = "modules.availability_zone.aws_route_table.public_route_table"
  }
}

/**
* A route from the public route table out to the internet through the internet
* gateway.
*/
resource "aws_route_table" "public_rt" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }
}

/**
* Associate the public route table with the public subnets.
*/
resource "aws_route_table_association" "public" {
  count          = var.public_subnets_count
  subnet_id      = element(aws_subnet.public_subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}