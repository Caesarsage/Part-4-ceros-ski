output "elastic_ip_id" {
  value = aws_eip.eip_for_the_nat_gateway.id
}