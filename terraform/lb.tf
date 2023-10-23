
resource "aws_lb" "lb" {
  name                       = "demo-lb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.ecs_tasks_sg.id]
  enable_deletion_protection = false
  subnets                    = module.vpc.public_subnets
}

resource "aws_lb_target_group" "lb_tg" {
  name        = "demo-tg"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = module.vpc.vpc_id
  health_check {
    enabled             = true
    interval            = 30
    path                = "/health"
    port                = "8000"
    protocol            = "HTTP"
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = 8000
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08" # Choose an appropriate SSL policy based on your needs
  certificate_arn   = aws_acm_certificate.ecs_api_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}





