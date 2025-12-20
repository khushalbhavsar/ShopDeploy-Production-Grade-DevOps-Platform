#==============================================================================
# ShopDeploy - ECR Module
# Elastic Container Registry for Docker Images
#==============================================================================

#------------------------------------------------------------------------------
# ECR Repositories
#------------------------------------------------------------------------------
resource "aws_ecr_repository" "main" {
  for_each = toset(var.repositories)

  name                 = "${var.project_name}-${var.environment}-${each.value}"
  image_tag_mutability = var.enable_tag_immutability ? "IMMUTABLE" : "MUTABLE"

  image_scanning_configuration {
    scan_on_push = var.enable_image_scanning
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = merge(var.tags, {
    Name      = "${var.project_name}-${var.environment}-${each.value}"
    Component = each.value
  })
}

#------------------------------------------------------------------------------
# Lifecycle Policy - Image Retention
#------------------------------------------------------------------------------
resource "aws_ecr_lifecycle_policy" "main" {
  for_each = toset(var.repositories)

  repository = aws_ecr_repository.main[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_retention_count} images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v", "release", "prod", "staging"]
          countType     = "imageCountMoreThan"
          countNumber   = var.image_retention_count
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Remove untagged images older than 7 days"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 7
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 3
        description  = "Remove development images older than 14 days"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["dev", "test", "feature"]
          countType     = "sinceImagePushed"
          countUnit     = "days"
          countNumber   = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

#------------------------------------------------------------------------------
# Repository Policy - Cross-Account Access (Optional)
#------------------------------------------------------------------------------
resource "aws_ecr_repository_policy" "main" {
  for_each = var.cross_account_ids != null ? toset(var.repositories) : toset([])

  repository = aws_ecr_repository.main[each.value].name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CrossAccountAccess"
        Effect = "Allow"
        Principal = {
          AWS = [for id in var.cross_account_ids : "arn:aws:iam::${id}:root"]
        }
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ]
      }
    ]
  })
}
