data "aws_route53_zone" "myzone" {
  name = "alschmic.people.aws.dev." # Replace this with your domain name (notice the trailing dot)
}

data "aws_acm_certificate" "my_certificate" {
  domain   = "alschmic.people.aws.dev"
  statuses = ["ISSUED"]
}

resource "aws_acm_certificate" "api_certificate" {
  domain_name       = "api.alschmic.people.aws.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.api_certificate.arn
  validation_record_fqdns = [for record in aws_acm_certificate.api_certificate.domain_validation_options : record.resource_record_name]

  depends_on = [
    aws_route53_record.cert_validation_dns
  ]
}

resource "aws_route53_record" "cert_validation_dns" {
  for_each = {
    for dvo in aws_acm_certificate.api_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.myzone.id
  records = [each.value.record]
  ttl     = 60
}


resource "aws_route53_record" "ecs_alb_record" {
  zone_id = data.aws_route53_zone.myzone.id
  name    = "ecs.alschmic.people.aws.dev"
  type    = "A"
  
  alias {
    name                   = aws_lb.lb.dns_name
    zone_id                = aws_lb.lb.zone_id
    evaluate_target_health = false
  }
}
resource "aws_acm_certificate" "ecs_api_certificate" {
  domain_name       = "ecs.alschmic.people.aws.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "ecs_cert_validation" {
  certificate_arn         = aws_acm_certificate.ecs_api_certificate.arn
  validation_record_fqdns = [for record in aws_acm_certificate.ecs_api_certificate.domain_validation_options : record.resource_record_name]

  depends_on = [
    aws_route53_record.ecs_cert_validation_dns
  ]
}

resource "aws_route53_record" "ecs_cert_validation_dns" {
  for_each = {
    for dvo in aws_acm_certificate.ecs_api_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.myzone.id
  records = [each.value.record]
  ttl     = 60
}
resource "aws_acm_certificate" "eks_api_certificate" {
  domain_name       = "eks.alschmic.people.aws.dev"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_acm_certificate_validation" "eks_cert_validation" {
  certificate_arn         = aws_acm_certificate.eks_api_certificate.arn
  validation_record_fqdns = [for record in aws_acm_certificate.eks_api_certificate.domain_validation_options : record.resource_record_name]

  depends_on = [
    aws_route53_record.eks_cert_validation_dns
  ]
}

resource "aws_route53_record" "eks_cert_validation_dns" {
  for_each = {
    for dvo in aws_acm_certificate.eks_api_certificate.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  type    = each.value.type
  zone_id = data.aws_route53_zone.myzone.id
  records = [each.value.record]
  ttl     = 60
}

data "aws_lb" "this" {
  name = "k8s-appdemou-appdemou-d3cf948f09"
}

resource "aws_route53_record" "eks_alb_record" {
  zone_id = data.aws_route53_zone.myzone.id
  name    = "eks.alschmic.people.aws.dev"
  type    = "A"

  alias {
    name                   = data.aws_lb.this.dns_name
    zone_id                = data.aws_lb.this.zone_id
    evaluate_target_health = false
  }
}