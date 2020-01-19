output "rds_endpoint" {
    value = join(",", aws_db_instance.db_server.*.address)
}

output "rds_arn" {
    value = join(",", aws_db_instance.db_server.*.arn)
}