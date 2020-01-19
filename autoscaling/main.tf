variable "ami_id" {
    default = ""
}

variable "key_name" {
    default = ""
}

variable "instance_type" {
    default = ""
}

variable "sg_id" {
    default = ""
}

variable "public_subnets_id" {
    default = []
}

variable "alb_target_group_arn" {
    default = ""
}

resource "aws_launch_configuration" "example_as_conf" {
    name_prefix                 = "webserver"
    image_id                    = var.ami_id
    instance_type               = var.instance_type
    key_name                    = var.key_name
    security_groups             = [var.sg_id]
    associate_public_ip_address = true
    user_data                   = file("./ec2/setup.sh")

    lifecycle {
        create_before_destroy   = true
    }
}

resource "aws_autoscaling_group" "example_asg" {
    name_prefix                 = "turedure-websv-v1"
    max_size                    = 4
    min_size                    = 1
    launch_configuration        = aws_launch_configuration.example_as_conf.name
    vpc_zone_identifier         = split(",", var.public_subnets_id)
    # Number of creating instance size when initialize auto scaling group
    desired_capacity            = 1

    health_check_grace_period   = 300
    health_check_type           = "ELB"
    target_group_arns           = [var.alb_target_group_arn]

    force_delete                = true

    lifecycle {
        create_before_destroy   = true
    }

    tags = [
        {
            key                 = "Name"
            value               = "test-autoscaling-group"
            propagate_at_launch  = false
        },
        {
            key                 = "Environment"
            value               = "development"
            propagate_at_launch = false
        }
    ]
}

resource "aws_autoscaling_policy" "scale_out" {
    name                   = "Instance-Scaleout-Policy"
    scaling_adjustment     = 1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.example_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
    name                   = "Instance-Scalein-policy"
    scaling_adjustment     = -1
    adjustment_type        = "ChangeInCapacity"
    cooldown               = 300
    autoscaling_group_name = aws_autoscaling_group.example_asg.name
}

resource "aws_cloudwatch_metric_alarm" "cpu_usage_high" {
    alarm_name             = "test-cpu-usage-high"
    comparison_operator    = "GreaterThanOrEqualToThreshold"
    evaluation_periods     = "1"
    metric_name            = "CPUUtilization"
    namespace              = "AWS/EC2"
    period                 = "300"
    statistic              = "Average"
    dimensions             = {
        AutoScalingGroupName = aws_autoscaling_group.example_asg.name
    }
    alarm_actions          = [aws_autoscaling_policy.scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "cpu_usage_low" {
    alarm_name             = "test-cpu-usage-low"
    comparison_operator    = "LessThanThreshold"
    evaluation_periods     = "1"
    metric_name            = "CPUUtilization"
    namespace              = "AWS/EC2"
    period                 = "300"
    statistic              = "Average"
    dimensions             = {
        AutoScalingGroupName = aws_autoscaling_group.example_asg.name
    }
    alarm_actions          = [aws_autoscaling_policy.scale_in.arn]
}