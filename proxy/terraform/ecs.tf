resource "aws_lb_target_group" "haproxy_tg" {
  name        = "haproxy-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.aws_vpc.demo.id
  target_type = "ip"

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/healthz"
    interval            = 30
    port                = 8080
    protocol            = "HTTP"
  }
}
resource "aws_lb_target_group" "haproxy_tg_stats" {
  name        = "haproxy-tg-stats"
  port        = 8404
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.demo.id
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    path                = "/healthz"
    interval            = 30
    port                = 8080
    protocol            = "HTTP"
  }
}
####################


# HAProxy ECS Task
resource "aws_ecs_task_definition" "haproxy_task" {
  family                   = "haproxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  task_role_arn            = aws_iam_role.haproxy_execution_role.arn
  execution_role_arn       = aws_iam_role.haproxy_execution_role.arn
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  container_definitions = jsonencode([
    {
      name  = "haproxy"
      image = "${aws_ecr_repository.haproxy_repo.repository_url}:latest" # Use your HAProxy image
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        },
        {
          containerPort = 8080
          hostPort      = 8080
        },
        {
          containerPort = 8404
          hostPort      = 8404
        }
      ]
      linuxParameters = {
        initProcessEnabled = true
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }
      # Add other necessary configurations, environment variables, volumes, etc.
    }
  ])
}

# HAProxy ECS Service
resource "aws_ecs_service" "haproxy_service" {
  name            = "haproxy-service"
  cluster         = data.aws_ecs_cluster.demo.id
  task_definition = aws_ecs_task_definition.haproxy_task.arn

  launch_type = "FARGATE"
  #force_new_deployment               = true
  enable_execute_command = true
  desired_count          = 1 # number of tasks you want to run

  network_configuration {
    subnets         = data.aws_subnets.demo_private.ids # Replace with your subnet IDs
    security_groups = [aws_security_group.haproxy_lb_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.haproxy_tg.arn
    container_name   = "haproxy"
    container_port   = 80
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.haproxy_tg_stats.arn
    container_name   = "haproxy"
    container_port   = 8404
  }

  depends_on = [aws_lb_listener.haproxy_https_listener] /*, aws_lb_listener.listener_stats*/
}
