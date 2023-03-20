# ==============================| Outputs |====================================
output "vpc_id" {
  value = aws_vpc.main.id
}

output "vpc_cidr" {
  value = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  value = {
    for az, spec in aws_subnet.public_subnets:
    az => spec.id
  }
}

output "private_subnet_ids" {
  value = {
    for az, spec in aws_subnet.private_subnets:
    az => spec.id
  }
}
