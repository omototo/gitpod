resource "aws_ecr_repository_policy" "lambda_ecr_policy" {
  repository = aws_ecr_repository.lambda_repo.name

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowLambdaPull",
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_docker_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_policy" "s3_access" {
  name        = "LambdaS3Access"
  description = "Grant S3 access to Lambda"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          //"s3:DeleteObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = ["arn:aws:s3:::hello-demo-images-bucket", "arn:aws:s3:::hello-demo-images-bucket/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_s3_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role" "api_gateway_cloudwatch_logs" {
  name = "ApiGatewayCloudWatchLogs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Effect = "Allow",
        Sid    = ""
      }
    ]
  })
}

resource "aws_iam_role_policy" "api_gateway_cloudwatch_logs" {
  name = "ApiGatewayCloudWatchLogs"
  role = aws_iam_role.api_gateway_cloudwatch_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:FilterLogEvents"
        ],
        Resource = "*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_api_gateway_account" "logging" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_logs.arn
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_policy" "ecs_cloudwatch_logs_policy" {
  name        = "ECSCloudWatchLogsAccess"
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
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_cloudwatch_logs_policy.arn
}

# Inline policy for ECR access
resource "aws_iam_policy" "ecs_execution_role_ecr_policy" {
  name        = "ECRECSAccess"
  description = "Allows ECS tasks to pull images from ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer"
      ],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_ecr_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_execution_role_ecr_policy.arn
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_attach" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logs_attach" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "ecs_exec_policy" {
  name        = "ECSExecPolicy"
  description = "Policy to enable ECS Exec."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "ecs:UpdateContainerInstancesState",
          "ecs:StartTask",
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ],
        Effect   = "Allow",
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attachment" {
  policy_arn = aws_iam_policy.ecs_exec_policy.arn
  role       = aws_iam_role.ecs_execution_role.name
}

resource "aws_iam_role" "eks_worker_node_role" {
  name = "EKSWorkerNodeRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "eks.amazonaws.com",
            "ec2.amazonaws.com",
            "eks-fargate-pods.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      },
      {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::334118252355:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/CE4A3DDA2B7E2EBA5DEE235173AEA332"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.eu-central-1.amazonaws.com/id/CE4A3DDA2B7E2EBA5DEE235173AEA332:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
  })
}

resource "aws_iam_policy" "eks_worker_node_s3_ecr_policy" {
  name        = "EKSWorkerNodeS3ECRAccess"
  description = "Allows EKS worker nodes to access S3 and ECR"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Effect   = "Allow",
        Resource = ["arn:aws:s3:::demo-images-imagemagick", "arn:aws:s3:::hello-demo-images-bucket/*"]
      },
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Effect   = "Allow",
        Resource = "*" # assuming access to all ECR repositories; narrow down if needed.
      }
    ]
  })
}



resource "aws_iam_role_policy_attachment" "eks_worker_node_s3_ecr_attach" {
  role       = aws_iam_role.eks_worker_node_role.name
  policy_arn = aws_iam_policy.eks_worker_node_s3_ecr_policy.arn
}

/*TODO: add proper tf to generate role

{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::334118252355:oidc-provider/oidc.eks.eu-central-1.amazonaws.com/id/CE4A3DDA2B7E2EBA5DEE235173AEA332"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.eu-central-1.amazonaws.com/id/CE4A3DDA2B7E2EBA5DEE235173AEA332:aud": "sts.amazonaws.com"
                }
            }
        }
    ]
}


*/