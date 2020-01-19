provider "aws" {
    region  = var.region
    profile = var.profile
}

module "network" {
    vpc_parameter = var.vpc_parameter
    source        = "./network"
}

module "sg" {
    vpc_id        = module.network.vpc_id
    ssh_ip        = var.ssh_ip
    natgw_ip      = module.network.natgw_ips
    source        = "./sg"
}

module "ec2" {
    instance_type = var.instance_type
    key_file_name = var.ssh_key_file_name
    vpc_id        = module.network.vpc_id
    subnet_ids    = module.network.public_subnets_id
    subnet_ips    = var.vpc_parameter.public_subnets
    sg_id         = module.sg.ec2_sg
    source        = "./ec2"
}

module "alb" {
    public_subnet_ids_str = module.network.public_subnets_id
    public_subnet_ips     = var.vpc_parameter.public_subnets
    vpc_id                = module.network.vpc_id
    instance_ids_str      = module.ec2.instance_ids
    alb_sg_id             = module.sg.alb_sg
    source                = "./alb"
}

module "auto_scaling" {
    ami_id               = module.ec2.ami_id
    key_name             = module.ec2.key_name
    instance_type        = var.instance_type
    sg_id                = module.sg.ec2_sg
    public_subnets_id    = module.network.public_subnets_id
    alb_target_group_arn = module.alb.target_group_arn
    source               = "./autoscaling"
}

module "rds" {
    private_subnets_ids  = module.network.private_subnets_id
    db_security_group_id = module.sg.rds_sg
    db_parameter_group   = var.db_parameter_group
    db_identifilter      = var.db_identifilter
    rds_name             = "testrds"
    source               = "./rds"
}

output "vpc_id" {
    value         = module.network.vpc_id
}

output "ec2_instance_ids" {
    value         = module.ec2.instance_public_ip
}

output "alb_public_dns" {
    value         = module.alb.alb_dns
}

output "rds_endpoint" {
    value         = module.rds.rds_endpoint
}

output "rds_arn" {
    value         = module.rds.rds_arn
}