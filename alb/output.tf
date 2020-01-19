output "alb_id" {
    value = aws_lb.example_alb.id
}

output "alb_arn" {
    value = aws_lb.example_alb.arn
}

output "alb_dns" {
    value = aws_lb.example_alb.dns_name
}

output "target_group_arn" {
    value = aws_lb_target_group.example_alb.arn
}