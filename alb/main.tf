variable "public_subnet_ids_str" {
    default = ""
}

variable "public_subnet_ips" {
    default = {}
}

variable "vpc_id" {
    default = ""
}

variable "instance_ids_str" {
    type    = string
    default = ""
}

variable "alb_sg_id" {
    default = ""
}

locals {
    instance_ids_list   = split(",", var.instance_ids_str)
    public_subnets_list = split(",", var.public_subnet_ids_str)
}

################################################
# S3 bucket to writing access logs Settings    #
################################################
resource "aws_s3_bucket" "alb-logs-bucket" {
    bucket        = "turedure-alb-logs-bucket-test-one"
    acl           = "private"
    # For test
    force_destroy = true

    lifecycle_rule {
        enabled = true
        id      = "alb-log"
        prefix  = "alb-log/"

        transition {
            days          = 30
            storage_class = "STANDARD_IA"
        }
        transition {
            days          = 60
            storage_class = "GLACIER"
        }
        expiration {
            days          = 90
        }
    }
}

resource "aws_s3_bucket_public_access_block" "alb-logs-bucket" {
    bucket                  = aws_s3_bucket.alb-logs-bucket.id
    block_public_acls       = true
    block_public_policy     = true
    ignore_public_acls      = true
    restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "alb-logs-bucket-policy" {
    bucket = aws_s3_bucket.alb-logs-bucket.id
    policy = data.aws_iam_policy_document.alb_log.json

    depends_on = [aws_s3_bucket_public_access_block.alb-logs-bucket]
}

# Bucket Policy
data "aws_iam_policy_document" "alb_log"{
    statement {
        effect    = "Allow"
        actions   = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${aws_s3_bucket.alb-logs-bucket.id}/*"]

        principals {
            type = "AWS"
            identifiers = ["582318560864"]
        }
    }
}

################################################
# ALB                                          #
################################################
resource "aws_lb" "example_alb" {
    name               = "turedure-example-alb"
    internal           = false
    load_balancer_type = "application"
    security_groups    = [var.alb_sg_id]
    subnets            = local.public_subnets_list

    access_logs {
        bucket         = aws_s3_bucket.alb-logs-bucket.bucket
        enabled        = true
    }

    tags = {
        Name           = "Test-Alb"
        Environment    = "development"
    }

    # S3のアクセス許可が出るまでペンディング
    depends_on         = [aws_s3_bucket_policy.alb-logs-bucket-policy]
}

resource "aws_lb_target_group" "example_alb" {
    name                 = "turedure-example-target-group"
    port                 = 80
    protocol             = "HTTP"
    deregistration_delay = 300
    vpc_id               = var.vpc_id

    health_check {
        interval            = 30
        path                = "/index.html"
        port                = 80
        timeout             = 5
        unhealthy_threshold = 2
        matcher             = 200
    }
    depends_on          = [aws_lb.example_alb]
}

resource "aws_lb_listener" "example_alb" {
    load_balancer_arn  = aws_lb.example_alb.arn
    port               = "80"
    protocol           = "HTTP"
    default_action {
        target_group_arn = aws_lb_target_group.example_alb.arn
        type             = "forward"
    }
    depends_on         = [aws_lb_listener.example_alb]
}

resource "aws_lb_target_group_attachment" "example_alb" {
    count              = length(var.public_subnet_ips)
    target_group_arn   = aws_lb_target_group.example_alb.arn
    target_id          = element(local.instance_ids_list, count.index)
    port               = 80
    depends_on         = [aws_lb.example_alb]
}