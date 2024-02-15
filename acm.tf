# #---------
# # ACM
# #---------
resource "aws_acm_certificate" "tokyo-cert" {
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route53_zone.route53_zone]

}

resource "aws_route53_record" "route53_acm_dns_resolve" {
  for_each = {
    for dvo in aws_acm_certificate.tokyo-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  allow_overwrite = true
  zone_id         = aws_route53_zone.route53_zone.zone_id
  name            = each.value.name
  type            = each.value.type
  ttl             = 600
  records         = [each.value.record]

}

resource "aws_acm_certificate_validation" "cert_valid" {
  certificate_arn         = aws_acm_certificate.tokyo-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.route53_acm_dns_resolve : record.fqdn]
}

# virginia region
resource "aws_acm_certificate" "bvirginia-cert" {
  provider          = aws.virginia
  domain_name       = "*.${var.domain}"
  validation_method = "DNS"

  tags = {
    Name    = "${var.project}-${var.environment}-wildcard-sslcert"
    Project = var.project
    Env     = var.environment
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_route53_zone.route53_zone]

}
# # -----------------
# # auto scalling group
# # -----------
resource "aws_autoscaling_group" "app_asg" {
  name = "${var.project}-${var.environment}-app-asg"

  desired_capacity = 1
  max_size         = 1
  min_size         = 1

  vpc_zone_identifier  = [aws_subnet.public_subnet_1a.id, aws_subnet.public_subnet_1c.id]

  health_check_type         = "ELB"
  health_check_grace_period = 300
  force_delete              = true

  target_group_arns = [
    aws_lb_target_group.alb_target_group.arn
  ]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.app_lt.id
        version            = "$Latest"
      }
      override {
        instance_type = "t2.micro"
      }
    }
  }
}