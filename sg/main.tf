variable "vpc_id" {
    default = ""
}
variable "ssh_ip" {
    default = ""
}
variable "natgw_ip" {
    default = ""
}

################################################
# Security Group for ALB                       #
################################################
resource "aws_security_group" "alb_sg" {
    name   = "alb-sg"
    vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "ingress_http" {
    type              = "ingress"
    from_port         = 80
    to_port           = 80
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "ingress_https" {
    type              = "ingress"
    from_port         = 443
    to_port           = 443
    protocol          = "tcp"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "egress_all_alb" {
    type              = "egress"
    from_port         = 0
    to_port           = 0
    protocol          = "-1"
    cidr_blocks       = ["0.0.0.0/0"]
    security_group_id = aws_security_group.alb_sg.id
}

################################################
# Security Group for EC2                       #
################################################
resource "aws_security_group" "ec2_sg" {
    name              = "ec2-sg"
    vpc_id            = var.vpc_id
}

resource "aws_security_group_rule" "ingress_http_from_alb" {
    type                     = "ingress"
    from_port                = 80
    to_port                  = 80
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.alb_sg.id
    security_group_id        = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "ingress_https_from_alb" {
    type                     = "ingress"
    from_port                = 443
    to_port                  = 443
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.alb_sg.id
    security_group_id        = aws_security_group.ec2_sg.id
}
resource "aws_security_group_rule" "ingress_ssh" {
    type                     = "ingress"
    from_port                = 22
    to_port                  = 22
    protocol                 = "tcp"
    cidr_blocks              = ["${var.ssh_ip}/32"]
    security_group_id        = aws_security_group.ec2_sg.id
}

resource "aws_security_group_rule" "egress_all_ec2" {
    type                     = "egress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "-1"
    cidr_blocks              = ["0.0.0.0/0"]
    security_group_id        = aws_security_group.ec2_sg.id
}

################################################
# Security Group for RDS                       #
################################################

locals {
    nat_gateway_ips          = split(",", var.natgw_ip)
}
resource "aws_security_group" "rds_sg" {
    vpc_id                   = var.vpc_id
    name                     = "rds-sg"
}

resource "aws_security_group_rule" "ingress_mysql_from_ec2" {
    type                     = "ingress"
    from_port                = 3306
    to_port                  = 3306
    protocol                 = "tcp"
    source_security_group_id = aws_security_group.ec2_sg.id
    security_group_id        = aws_security_group.rds_sg.id
}

resource "aws_security_group_rule" "egress_all_rds" {
    type                     = "egress"
    from_port                = 0
    to_port                  = 0
    protocol                 = "tcp"
    cidr_blocks              = [for ip in local.nat_gateway_ips : "${ip}/32"]
    security_group_id        = aws_security_group.rds_sg.id
}


