variable "cluster_name" {
  type        = string
  description = "EKS Cluster Name"
}

variable "cluster_region" {
  type        = string
  description = "AWS Region"
}

variable "node_instance_types" {
  type        = list(string)
  description = "Instance types for spot nodes"
}

variable "desired_nodes" {
  type        = number
  description = "Desired node count"
}

variable "min_nodes" {
  type        = number
  description = "Minimum nodes"
}

variable "max_nodes" {
  type        = number
  description = "Maximum nodes"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnets for EKS nodes"
}

variable "key_name" {
  type = string 
  description = "Key for Spot instance"
}
variable "vpc_id" {
  type = string 
  description = "VPC ID"
}

variable "sg_id" {
  description = "Security group nodes"
  type        = string
}


