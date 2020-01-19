output "vpc_id" {
    value = aws_vpc.example_vpc.id
}

output "private_subnets_id" {
    value = join(",", aws_subnet.example_private.*.id)
}

output "public_subnets_id" {
    value = join(",", aws_subnet.example_public.*.id)
}

output "natgw_ips" {
    value = join(",", aws_nat_gateway.nat_gateway.*.public_ip)
}
