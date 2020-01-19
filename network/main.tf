######################################
# Varibales                          #
######################################
variable "vpc_parameter" {
    default = {
        vpc_subnets       = "10.0.0.0/16"
        public_subnets    = {
            "0" = "10.0.1.0/24",
            "1" = "10.0.2.0/24"
        },
        private_subnets   = {
            "0" = "10.0.5.0/24",
            "1" = "10.0.6.0/24"
        },
        availability_zones = {
            "0" = "ap-northeast-1a",
            "1" = "ap-northeast-1c"
        }
    }
}

######################################
# VPC                                #
######################################
resource "aws_vpc" "example_vpc" {
    cidr_block           = var.vpc_parameter.vpc_subnets
    enable_dns_support   = true # DNS名前解決をサポート
    enable_dns_hostnames = true # パブリックIPアドレスをもつインスタンスの名前解決を有効化

    tags = {
        Name = "Example"
    }
}

######################################
# Public Subnet                      #
######################################
resource "aws_subnet" "example_public" {
    vpc_id                  = aws_vpc.example_vpc.id
    count                   = length(var.vpc_parameter.public_subnets)
    cidr_block              = lookup(var.vpc_parameter.public_subnets     , count.index, "Not Found")
    availability_zone       = lookup(var.vpc_parameter.availability_zones, count.index, "Not Found")
    map_public_ip_on_launch = true

    tags = {
        Name = format("Example-VPC-Public-Subnet-%d", count.index)
    }
}

######################################
# Private Subnet                     #
######################################
resource "aws_subnet" "example_private" {
    vpc_id                 = aws_vpc.example_vpc.id
    count                  = length(var.vpc_parameter.private_subnets)
    cidr_block             = lookup(var.vpc_parameter.private_subnets    , count.index, "Not Found")
    availability_zone      = lookup(var.vpc_parameter.availability_zones, count.index, "Not Found")
    tags = {
        Name = format("Example-VPC-Private-Subnet-%d", count.index)
    }
}

######################################
# Public Network Settings            #
######################################

# Internet Gateway
resource "aws_internet_gateway" "example_igw" {
    vpc_id = aws_vpc.example_vpc.id
}

# Route Table
resource "aws_route_table" "public_route_table" {
    vpc_id = aws_vpc.example_vpc.id

    tags   = {
        Name = "RouteTable_for_public_subnets"
    }
}
# Route Mappings
resource "aws_route" "public_route_for_internet_gateway" {
    route_table_id         = aws_route_table.public_route_table.id
    gateway_id             = aws_internet_gateway.example_igw.id
    destination_cidr_block = "0.0.0.0/0"
}
# Attaching Route Table
resource "aws_route_table_association" "association_table_to_public_subnets" {
    count                  = length(var.vpc_parameter.public_subnets)
    route_table_id         = aws_route_table.public_route_table.id
    subnet_id              = element(aws_subnet.example_public.*.id, count.index)
}

######################################
# Private Network Settings           #
######################################

# Elastic IP
resource "aws_eip" "eip_for_nat_gateway" {
    count          = length(var.vpc_parameter.public_subnets)
    vpc            = true
    depends_on     = [aws_internet_gateway.example_igw]

    tags           = {
        Name = format("EIP-Located-Public%d", count.index)
    }
}

# Nat Gateway
resource "aws_nat_gateway" "nat_gateway" {
    count         = length(var.vpc_parameter.private_subnets)
    allocation_id = element(aws_eip.eip_for_nat_gateway.*.id, count.index)
    subnet_id     = element(aws_subnet.example_public.*.id, count.index)
    depends_on    = [aws_internet_gateway.example_igw]

    tags          = {
        Name = format("NGW-Located-Public%d", count.index)
    }
}

# Route Table for private subnet 1
resource "aws_route_table" "private_route_table" {
    count  = length(var.vpc_parameter.private_subnets)
    vpc_id = aws_vpc.example_vpc.id
}



# Route
resource "aws_route" "private_route_for_nat_gateway" {
    count                  = length(aws_route_table.private_route_table.*.id)
    route_table_id         = element(aws_route_table.private_route_table.*.id, count.index)
    nat_gateway_id         = element(aws_nat_gateway.nat_gateway.*.id, count.index)
    destination_cidr_block = "0.0.0.0/0"

    depends_on             = [aws_nat_gateway.nat_gateway]
}

# Attach Route Table
resource "aws_route_table_association" "association_table_to_private_subnets" {
    count          = length(var.vpc_parameter.private_subnets)
    subnet_id      = element(aws_subnet.example_private.*.id, count.index)
    route_table_id = element(aws_route_table.private_route_table.*.id, count.index)
}









