output "vpc_id" {
    value = aws_vpc.vpc.id
}
output "public_subnets" {
    value = aws_subnet.public_subnet[*].id
}
output "private_subnets" {
    value = aws_subnet.private_subnet[*].id
}
output "protected_subnet" {
  value = aws_subnet.protected_subnet[*].id
}
output "public_rts" {
    value = aws_route_table.public_rt[*].id
}
output "private_rts" {
    value = aws_route_table.private_rt[*].id
}