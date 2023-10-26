#LB for HAProxy
resource "aws_lb" "haproxy_lb" {
  name               = "haproxy-lb"
  internal           = false # Set to true if you want this LB to be internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.haproxy_lb_sg.id]
  subnets            = data.aws_subnets.demo_public.ids

  enable_deletion_protection = false
  depends_on                 = [data.aws_subnets.demo_public]
}

resource "aws_security_group" "haproxy_lb_sg" {
  name        = "haproxy-lb-sg"
  description = "Security Group for HAProxy Load Balancer"
  vpc_id      = data.aws_vpc.demo.id

  # Existing ingress rule for port 443
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # New ingress rule for port 8080 (health check)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # New ingress rule for port 8404 (stats)
  ingress {
    from_port   = 8404
    to_port     = 8404
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Existing egress rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_listener" "haproxy_https_listener" {
  load_balancer_arn = aws_lb.haproxy_lb.arn
  port              = 80
  protocol          = "HTTP"
  #ssl_policy        = "ELBSecurityPolicy-2016-08" # Choose an appropriate SSL policy based on your needs
  #certificate_arn   = data.aws_acm_certificate.my_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.haproxy_tg.arn
  }
}

resource "aws_lb_listener_rule" "stats_rule" {
  listener_arn = aws_lb_listener.haproxy_https_listener.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.haproxy_tg_stats.arn
  }

  condition {
    path_pattern {
      values = ["/stats*"]
    }
  }
}


/*data "aws_route53_zone" "myzone" {
  name = "alschmic.people.aws.dev." # Replace this with your domain name (notice the trailing dot)
}

resource "aws_route53_record" "wildcard_alb_record" {
  zone_id = data.aws_route53_zone.myzone.id
  name    = "alschmic.people.aws.dev" # Replace this with your domain name
  type    = "A"

  alias {
    name                   = aws_lb.haproxy_lb.dns_name
    zone_id                = aws_lb.haproxy_lb.zone_id
    evaluate_target_health = false
  }
}
*/
