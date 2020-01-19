variable private_subnets_ids {
    default = ""
}
variable db_security_group_id {
    default = ""
}

variable db_parameter_group {
    default = {}
}

variable rds_name {
    default = ""
}

variable db_identifilter {
    default = {}
}

resource "aws_db_parameter_group" "db_parameter" {
    name     = "${var.db_parameter_group.name}-parameter"
    family   = var.db_parameter_group.family

    parameter {
        name  = "character_set_server"
        value = "utf8"
    }

    parameter {
        name  = "character_set_client"
        value = "utf8"
    }
    
}

resource "aws_db_subnet_group" "db_subnets" {
    name       = "private-subnet"
    subnet_ids = split(",", var.private_subnets_ids)

    tags       = {
        Name = "Private Subnet"
    }
}

resource "aws_db_instance" "db_server" {
    identifier                 = "test"
    allocated_storage          = 20
    engine                     = "mysql"
    engine_version             = "5.7.22"
    instance_class             = "db.t2.micro"
    name                       = var.rds_name
    db_subnet_group_name       = aws_db_subnet_group.db_subnets.name
    vpc_security_group_ids     = [var.db_security_group_id]
    parameter_group_name       = aws_db_parameter_group.db_parameter.name
    multi_az                   = true
    backup_retention_period    = "7"
    backup_window              = "23:00-23:30"
    apply_immediately          = true
    auto_minor_version_upgrade = false
    username                  = var.db_identifilter.user_name
    password                   = var.db_identifilter.password
    skip_final_snapshot        = true
}

