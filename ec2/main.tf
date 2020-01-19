variable "vpc_id" {
    default = ""
}

variable "sg_id" {
    default = ""
}

variable "subnet_ids" {
    default = []
}

variable "subnet_ips" {
    default = {}
}

variable "key_file_name" {
    default = ""
}

variable "instance_type" {
    default = ""
}

locals {
    key_file        = "~/.ssh/${var.key_file_name}.pub"
}

###########################################
# Registered Key Pair                     #
###########################################
resource "aws_key_pair" "instance_ssh_key_pairs" {
    key_name        = "EC2 Instance SSH Key Pairs"
    public_key      = file(local.key_file)
}

###########################################
# Create EC2 instance                     #
###########################################

# Searh latest amazon linux image
data "aws_ami" "recent_amazon_linux_2"{
    most_recent = true
    owners      = ["amazon"]

    filter {
        name    = "architecture"
        values  = ["x86_64"]
    }
    filter {
        name    = "root-device-type"
        values  = ["ebs"]
    }
    filter {
        name    = "name"
        values  = ["amzn2-ami-hvm-2.0.????????.?-x86_64-gp2"]
    }
    filter {
        name    = "virtualization-type"
        values  = ["hvm"]
    }
    filter {
        name    = "block-device-mapping.volume-type"
        values  = ["gp2"]
    }

    depends_on  = [var.vpc_id]
}

resource "aws_instance" "web_servers" {
    count                  = length(var.subnet_ips)
    ami                    = data.aws_ami.recent_amazon_linux_2.id
    instance_type          = var.instance_type
    key_name               = aws_key_pair.instance_ssh_key_pairs.id
    vpc_security_group_ids = [var.sg_id]
    subnet_id              = element(split(",", var.subnet_ids), count.index)

    tags                   = {
        Name = "Test ELB Web Server ${count.index}"
    }

    user_data = file("./ec2/setup.sh")

    depends_on             = [var.subnet_ids]
}

