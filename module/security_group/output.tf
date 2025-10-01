output "sg_id" {
  description = "Security group ID for EKS nodes"
  value       = aws_security_group.security_group.id
}
