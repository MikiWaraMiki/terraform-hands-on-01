variable "region" {
}

variable "profile" {
}

###########################################
# For Network Parameter                   #
###########################################

variable "vpc_parameter" {
    default = {
        vpc_subnets       = "10.0.0.0/16",
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

###########################################
# EC2 Security group Parameter            #
###########################################
variable "ssh_ip" {
    default = {Your Public IP}
}

variable "ssh_key_file_name" {
    default = "terraform-test"
}

variable "instance_type" {
    default = "t2.micro"
}

###########################################
# RDS Parameter                           #
###########################################
variable "db_parameter_group" {
    default = {
        name   = "rds-test",
        family = "mysql5.7"
    }
}

variable "db_identifilter" {
    default = {
        user_name = {Your DB Name},
        password  = {Your DB Password}
    }
}