# # Connect with Docker unix socket
# provider "docker" {
#   host = "unix:///var/run/docker.sock"
# }


# # ECR repo creation
# resource "aws_ecr_repository" "lambda_repository" {
#   name                 = "lambda-api-snowflake-repo"
#   image_tag_mutability = "MUTABLE"
#   image_scanning_configuration {
#     scan_on_push = true
#   }
#   force_delete = true
  
#   tags = {
#     Environment = "development"
#   }
# }


# #AWS CLI login
# resource "null_resource" "ecr_login" {
#   provisioner "local-exec" {
#     command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.lambda_repository.repository_url}"
#   }

#   depends_on = [aws_ecr_repository.lambda_repository]
# }

# # detect code changes in lambda
# resource "null_resource" "lambda_source_changed" {
#   triggers = {
#     source_hash = sha1(join("", [
#       filesha1("${path.module}/resources/python/aws_lambda/lambda_function.py"),
#       filesha1("${path.module}/resources/python/aws_lambda/post.py"),
#       filesha1("${path.module}/resources/python/aws_lambda/get.py"),
#       filesha1("${path.module}/resources/python/aws_lambda/snowflake_response.py")
#     ]))
#   }
# }


# # Docker build using linux/amd64 architecture
# resource "null_resource" "build_docker_image" {
#   provisioner "local-exec" {
#     command = <<EOT
#       docker build -t lambda-api-snowflake -f ${path.module}/resources/Dockerfile ${path.module}/resources &&
#       docker tag lambda-api-snowflake:latest ${aws_ecr_repository.lambda_repository.repository_url}:latest
#     EOT
#   }
#   depends_on = [
#     null_resource.lambda_source_changed,
#     null_resource.ecr_login
#   ]
# }



# resource "null_resource" "build_docker_image" {
#   provisioner "local-exec" {
#     command = "docker build  -t aws_lambda:latest -f ${path.module}/resources/Dockerfile ${path.module}/resources && docker tag aws_lambda:latest ${aws_ecr_repository.lambda_repository.repository_url}:latest"
#   }

#   depends_on = [aws_ecr_repository.lambda_repository]
# }


# # Docker push
# resource "null_resource" "push_image" {
#   provisioner "local-exec" {
#     command = "docker push ${aws_ecr_repository.lambda_repository.repository_url}:latest"
#   }

#   depends_on = [
#     null_resource.build_docker_image,
#     null_resource.ecr_login
#   ]
# }


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

# AWS CLI login
resource "null_resource" "ecr_login" {
  provisioner "local-exec" {
    command = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.lambda_repository.repository_url}"
  }

  depends_on = [aws_ecr_repository.lambda_repository]
}

# Detect changes in lambda .py files
resource "null_resource" "lambda_source_changed" {
  triggers = {
    source_hash = sha1(join("", [
      filesha1("${path.module}/resources/python/aws_lambda/lambda_function.py"),
      filesha1("${path.module}/resources/python/aws_lambda/post.py"),
      filesha1("${path.module}/resources/python/aws_lambda/get.py"),
      filesha1("${path.module}/resources/python/aws_lambda/snowflake_response.py")
    ]))
  }
}

# Docker build and tag
resource "null_resource" "build_docker_image" {
  provisioner "local-exec" {
    command = <<EOT
      docker build -t lambda-api-snowflake -f ${path.module}/resources/Dockerfile ${path.module}/resources &&
      docker tag lambda-api-snowflake:latest ${aws_ecr_repository.lambda_repository.repository_url}:latest
    EOT
  }

  depends_on = [
    null_resource.lambda_source_changed,
    null_resource.ecr_login
  ]
}

# Push to ECR
resource "null_resource" "push_image" {
  provisioner "local-exec" {
    command = "docker push ${aws_ecr_repository.lambda_repository.repository_url}:latest"
  }

  depends_on = [
    null_resource.build_docker_image,
    null_resource.ecr_login
  ]
}

# Update Lambda function with new image
resource "null_resource" "update_lambda_function" {
  provisioner "local-exec" {
    command = "aws lambda update-function-code --function-name api-incd-docker-lambda --image-uri ${aws_ecr_repository.lambda_repository.repository_url}:latest"
  }

  depends_on = [
    null_resource.push_image
  ]
}
