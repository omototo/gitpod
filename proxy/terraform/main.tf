provider "aws" {
  region = var.aws_region
}

#ECR repo for HAProxy
resource "aws_ecr_repository" "haproxy_repo" {
  name = "demo-proxy"
}

resource "null_resource" "build_and_push_proxy" {
  provisioner "local-exec" {
    command = <<EOT
      cd ../docker
      $(aws ecr get-login --no-include-email --region ${var.aws_region})
      docker build -t ${aws_ecr_repository.haproxy_repo.repository_url} .
      docker tag ${aws_ecr_repository.haproxy_repo.repository_url} ${aws_ecr_repository.haproxy_repo.repository_url}:latest
      docker push ${aws_ecr_repository.haproxy_repo.repository_url}:latest
    EOT

    environment = {
      AWS_DEFAULT_REGION = var.aws_region
    }
  }
  triggers = {
    always_run = "${timestamp()}"
  }

  depends_on = [aws_ecr_repository.haproxy_repo]
}

#Populates haproxy.cfg file with the DNS name of the load balancer and API Gateway URL
locals {
  haproxy_config = templatefile("${path.module}/../docker/haproxy.cfg.tpl", {
    lb_dns_name = "ecs.alschmic.people.aws.dev:8000"
    eks_name    = "eks.alschmic.people.aws.dev:443"
    lambda_url  = "api.alschmic.people.aws.dev:443"
  })
}

resource "local_file" "haproxy_cfg" {
  content  = local.haproxy_config
  filename = "${path.module}/../docker/haproxy.cfg"
}

resource "null_resource" "deal_with_LF" {
  provisioner "local-exec" {
    command = <<EOT
      echo "" >> ../docker/haproxy.cfg
    EOT 
  }
  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [local_file.haproxy_cfg]
}