#==============================================================================
# ECR Module - Outputs
#==============================================================================

output "repository_urls" {
  description = "Map of repository names to URLs"
  value       = { for k, v in aws_ecr_repository.main : k => v.repository_url }
}

output "repository_arns" {
  description = "Map of repository names to ARNs"
  value       = { for k, v in aws_ecr_repository.main : k => v.arn }
}

output "repository_names" {
  description = "List of repository names"
  value       = [for k, v in aws_ecr_repository.main : v.name]
}

output "registry_id" {
  description = "The registry ID where the repository was created"
  value       = values(aws_ecr_repository.main)[0].registry_id
}
