#==============================================================================
# ECR Module - Variables
#==============================================================================

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "repositories" {
  description = "List of repository names to create"
  type        = list(string)
  default     = ["backend", "frontend"]
}

variable "image_retention_count" {
  description = "Number of images to retain"
  type        = number
  default     = 30
}

variable "enable_image_scanning" {
  description = "Enable image scanning on push"
  type        = bool
  default     = true
}

variable "enable_tag_immutability" {
  description = "Enable tag immutability"
  type        = bool
  default     = false
}

variable "cross_account_ids" {
  description = "List of AWS account IDs for cross-account access"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}
