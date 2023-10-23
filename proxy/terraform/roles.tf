#HAProxy permissions
resource "aws_iam_role" "haproxy_execution_role" {
  name = "haproxy_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "haproxy_execution_role_default" {
  role       = aws_iam_role.haproxy_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/haproxy"
  retention_in_days = 14 # you can modify this based on your retention needs
}

resource "aws_iam_policy" "ecs_cloudwatch_logs_policy" {
  name        = "ECSCloudWatchHAProxyLogsAccess"
  description = "Allows ECS tasks to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_cloudwatch_logs_attachment" {
  role       = aws_iam_role.haproxy_execution_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs_policy.arn
}

data "aws_iam_policy" "ecs_exec_policy" {
  name = "ECSExecPolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attachment" {
  policy_arn = data.aws_iam_policy.ecs_exec_policy.arn
  role       = aws_iam_role.haproxy_execution_role.name
}

resource "aws_iam_policy" "ecs_session_manager_policy" {
  name        = "ECSSessionManagerPolicy"
  description = "Policy for ECS Exec with Session Manager."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ssm:StartSession",
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_session_manager_attachment" {
  policy_arn = aws_iam_policy.ecs_session_manager_policy.arn
  role       = aws_iam_role.haproxy_execution_role.name
}
