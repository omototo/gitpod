
data "aws_ecs_cluster" "demo" {
  cluster_name = "demo-ecs-cluster"
}
data "aws_vpc" "demo" {
  tags = {
    Name = "demo-vpc"
  }
}
data "aws_lb" "demo" {
  name = "demo-lb"
}

data "aws_api_gateway_rest_api" "myapi" {
  name = "MyDemoAPI"
}

data "aws_subnets" "demo_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.demo.id]
  }
  filter {
    name   = "tag:Name"
    values = ["demo-vpc-public*"]
  }
}

data "aws_subnets" "demo_private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.demo.id]
  }
  filter {
    name   = "tag:Name"
    values = ["demo-vpc-private*"]
  }
}

data "aws_acm_certificate" "my_certificate" {
  domain   = "alschmic.people.aws.dev"
  statuses = ["ISSUED"]
}
