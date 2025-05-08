# Connect with Docker unix socket
provider "docker" {
  host = "unix:///var/run/docker.sock"
}


# ECR repo creation
resource "aws_ecr_repository" "lambda_repository" {
  name                 = "lambda-api-snowflake-repo"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = true
  }
  force_delete = true
  
  tags = {
    Environment = "development"
  }
}


#AWS CLI login
resource "null_resource" "ecr_login" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.lambda_repository.repository_url}"
  }

  depends_on = [aws_ecr_repository.lambda_repository]
}


# Docker build using linux/amd64 architecture
resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = <<EOT
      docker build -t lambda-api-snowflake -f ${path.module}/resources/Dockerfile ${path.module}/resources &&
      docker tag lambda-api-snowflake:latest ${aws_ecr_repository.lambda_repository.repository_url}:latest
    EOT
  }
  depends_on = [
    null_resource.ecr_login
  ]
}



resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = "docker build  -t aws_lambda:latest -f ${path.module}/resources/Dockerfile ${path.module}/resources && docker tag aws_lambda:latest ${aws_ecr_repository.lambda_repository.repository_url}:latest"
  }

  depends_on = [aws_ecr_repository.lambda_repository]
}


# Docker push
resource "null_resource" "push_image" {
  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.lambda_repository.repository_url}:latest"
  }

  depends_on = [
    null_resource.build_docker_image,
    null_resource.ecr_login
  ]
}

