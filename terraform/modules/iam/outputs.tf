#==============================================================================
# IAM Module - Outputs
#==============================================================================

output "eks_cluster_role_arn" {
  description = "ARN of EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Name of EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
}

output "eks_node_role_arn" {
  description = "ARN of EKS node group IAM role"
  value       = aws_iam_role.eks_node.arn
}

output "eks_node_role_name" {
  description = "Name of EKS node group IAM role"
  value       = aws_iam_role.eks_node.name
}

output "aws_lb_controller_role_arn" {
  description = "ARN of AWS Load Balancer Controller IAM role"
  value       = aws_iam_role.aws_lb_controller.arn
}

output "cluster_autoscaler_role_arn" {
  description = "ARN of Cluster Autoscaler IAM role"
  value       = aws_iam_role.cluster_autoscaler.arn
}
