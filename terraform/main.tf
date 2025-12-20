#==============================================================================
# ShopDeploy - Main Terraform Configuration
# Production-Grade AWS Infrastructure for E-Commerce Platform
#==============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }

  # Remote Backend Configuration - S3 + DynamoDB for State Locking
  backend "s3" {
    bucket         = "shopdeploy-terraform-state"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "shopdeploy-terraform-locks"
  }
}

#------------------------------------------------------------------------------
# AWS Provider Configuration
#------------------------------------------------------------------------------
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "ShopDeploy"
      Environment = var.environment
      ManagedBy   = "Terraform"
      Owner       = "DevOps-Team"
    }
  }
}

#------------------------------------------------------------------------------
# Data Sources
#------------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

#------------------------------------------------------------------------------
# Local Variables
#------------------------------------------------------------------------------
locals {
  cluster_name = "${var.project_name}-${var.environment}-eks"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#------------------------------------------------------------------------------
# VPC Module - Network Infrastructure
#------------------------------------------------------------------------------
module "vpc" {
  source = "./modules/vpc"

  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr            = var.vpc_cidr
  availability_zones  = slice(data.aws_availability_zones.available.names, 0, 3)
  public_subnet_cidrs = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway  = var.enable_nat_gateway
  single_nat_gateway  = var.single_nat_gateway
  cluster_name        = local.cluster_name

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# IAM Module - Identity and Access Management
#------------------------------------------------------------------------------
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = local.cluster_name

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# ECR Module - Container Registry
#------------------------------------------------------------------------------
module "ecr" {
  source = "./modules/ecr"

  project_name            = var.project_name
  environment             = var.environment
  image_retention_count   = var.ecr_image_retention_count
  enable_image_scanning   = true
  enable_tag_immutability = false

  repositories = ["backend", "frontend"]

  tags = local.common_tags
}

#------------------------------------------------------------------------------
# EKS Module - Kubernetes Cluster
#------------------------------------------------------------------------------
module "eks" {
  source = "./modules/eks"

  project_name          = var.project_name
  environment           = var.environment
  cluster_name          = local.cluster_name
  cluster_version       = var.eks_cluster_version
  vpc_id                = module.vpc.vpc_id
  private_subnet_ids    = module.vpc.private_subnet_ids
  eks_cluster_role_arn  = module.iam.eks_cluster_role_arn
  eks_node_role_arn     = module.iam.eks_node_role_arn

  # Node Group Configuration
  node_instance_types   = var.eks_node_instance_types
  node_desired_size     = var.eks_node_desired_size
  node_min_size         = var.eks_node_min_size
  node_max_size         = var.eks_node_max_size
  node_disk_size        = var.eks_node_disk_size

  # Enable Add-ons
  enable_cluster_autoscaler = true
  enable_metrics_server     = true
  enable_aws_lb_controller  = true

  tags = local.common_tags

  depends_on = [
    module.vpc,
    module.iam
  ]
}

#------------------------------------------------------------------------------
# Kubernetes Provider Configuration (Post-EKS)
#------------------------------------------------------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
  }
}

#------------------------------------------------------------------------------
# Helm Provider Configuration
#------------------------------------------------------------------------------
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", local.cluster_name]
    }
  }
}
