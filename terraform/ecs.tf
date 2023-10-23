
//ECS
resource "aws_ecs_cluster" "cluster" {
  name = "demo-ecs-cluster"
}

resource "aws_ecs_task_definition" "task_def" {
  family                   = "demo-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "4096"
  task_role_arn            = aws_iam_role.ecs_execution_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  #runtime_platform {
  #  operating_system_family = "LINUX"
  #  cpu_architecture        = "ARM64"
  #}
  container_definitions = jsonencode([{
    name  = "demo-container"
    image = "${aws_ecr_repository.container_repo.repository_url}:latest"
    portMappings = [{
      containerPort = 8000
    }]
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
    environment = [
      {
        name  = "DEPLOY_TIMESTAMP",
        value = "${timestamp()}"
      }
    ]
  }])
}

resource "aws_security_group" "ecs_tasks_sg" {
  name        = "ecs_tasks_sg"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8404
    to_port     = 8404
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  depends_on = [module.vpc]
}

resource "aws_ecs_service" "service" {
  name                 = "demo-service"
  cluster              = aws_ecs_cluster.cluster.id
  task_definition      = aws_ecs_task_definition.task_def.arn
  launch_type          = "FARGATE"
  desired_count        = 2
  force_new_deployment = true


  network_configuration {
    subnets         = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    container_name   = "demo-container"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.listener]
}

resource "aws_appautoscaling_target" "scale_target" {
  max_capacity       = 20
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "scale_policy" {
  name               = "ecs-scale-policy-avg"
  service_namespace  = aws_appautoscaling_target.scale_target.service_namespace
  scalable_dimension = aws_appautoscaling_target.scale_target.scalable_dimension
  resource_id        = aws_appautoscaling_target.scale_target.resource_id
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    target_value = 65
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}