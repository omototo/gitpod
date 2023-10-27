resource "aws_ecr_repository" "lambda_repo" {
  name = "demo-image-processor-lambda"
}

resource "aws_ecr_repository" "container_repo" {
  name = "demo-image-processor-container"
}

resource "null_resource" "build_and_push_lambda" {
  provisioner "local-exec" {
    command = <<EOT
      cd ../lambda
      $(aws ecr get-login --no-include-email --region ${var.aws_region})
      docker build -t ${aws_ecr_repository.lambda_repo.repository_url} .
      docker tag ${aws_ecr_repository.lambda_repo.repository_url} ${aws_ecr_repository.lambda_repo.repository_url}:latest
      docker push ${aws_ecr_repository.lambda_repo.repository_url}:latest
    EOT
    //aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin 334118252355.dkr.ecr.eu-central-1.amazonaws.com
    environment = {
      AWS_DEFAULT_REGION = var.aws_region
    }
  }
  /*triggers = {
    always_run = "${timestamp()}"
  }*/
  depends_on = [aws_ecr_repository.lambda_repo]
}

resource "null_resource" "build_and_push_container" {
  provisioner "local-exec" {
    command = <<EOT
      cd ../general
      $(aws ecr get-login --no-include-email --region ${var.aws_region})
      
      # Create a new builder instance
      docker buildx create --use --name multiarchbuilder
      
      # Starting up the instances, ensuring they are using the right drivers and are available
      docker buildx inspect multiarchbuilder --bootstrap

      # Building the multi-architecture image
      docker buildx build --platform linux/amd64,linux/arm64 -t ${aws_ecr_repository.container_repo.repository_url}:latest --push .

      # Clean up, remove the builder instance after the build is complete
      docker buildx rm multiarchbuilder
    EOT

    environment = {
      AWS_DEFAULT_REGION = var.aws_region
    }
  }

  triggers = {
    always_run = "${timestamp()}"
  }
  depends_on = [aws_ecr_repository.container_repo]
}
