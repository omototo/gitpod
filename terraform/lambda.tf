resource "aws_lambda_function" "lambda_image_processor" {
  function_name = "lambda-image-processor"
  role          = aws_iam_role.lambda_execution_role.arn
  image_uri     = "${aws_ecr_repository.lambda_repo.repository_url}:latest"

  memory_size = 128
  timeout     = 60
  architectures = ["arm64"]
  package_type = "Image"
  depends_on = [null_resource.build_and_push_lambda, aws_iam_role_policy_attachment.lambda_s3_attach, aws_ecr_repository_policy.lambda_ecr_policy]
}