# ================================================================================= #
# Reource Input
# ================================================================================= #
variable "aws_region" {
  description = "AWS REGION"
  type        = string
  default     = "ap-northeast-1"
}

variable "prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "pre"
}

variable "image_save_version" {
  type        = number
  default     = 7
  description = "Specify Save Image Version in ECR (When Create ECR)"
}

# ================================================================================= #
# Resource
# ================================================================================= #
# --------------------------------------------------------------------- #
# Service01 Ecr
# --------------------------------------------------------------------- #
resource "aws_ecr_repository" "Service01Ecr" {
  name                 = "${var.prefix}/service01"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "Service01EcrPolicy" {
  repository = aws_ecr_repository.Service01Ecr.name
  policy     = <<EOF
{
    "rules": [
        {
            "rulePriority": 1,
            "description": "Only keep ${var.image_save_version} images",
            "selection": {
                "tagStatus": "any",
                "countType": "imageCountMoreThan",
                
                "countNumber": ${var.image_save_version}
            },
            "action": {
                "type": "expire"
            }
        }
    ]
}
EOF
}
