variable "region" {
  description = "AWS Region"
  type        = string
  default     = "ca-central-1"
}

variable "cluster_name" {
  description = "EKS Cluster Name"
  type        = string
  default     = "dev-cluster"
}

variable "node_instance_types" {
  description = "Instance types for spot nodes"
  type        = list(string)
  default     = ["t3.medium", "t3.large", "t3.xlarge"]
}

variable "desired_nodes" {
  description = "Desired node count"
  type        = number
  default     = 4
}

variable "min_nodes" {
  description = "Minimum nodes"
  type        = number
  default     = 2
}

variable "max_nodes" {
  description = "Maximum nodes"
  type        = number
  default     = 5
}

variable "env" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "subnet_ids" {
  description = "Subnets for EKS nodes"
  type        = list(string)
  default     = ["subnet-0e19c34061556efcd", "subnet-070ba44fa3c124e36", "subnet-09d41a8413f4ca36d"]
}

variable "key_name" {
  description = "Key for Spot instance"
  type        = string
  default     = "democentralcanada"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
  default     = "vpc-0eaea9c562fcf4e54"
}
