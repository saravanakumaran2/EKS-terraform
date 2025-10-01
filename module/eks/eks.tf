resource "aws_eks_cluster" "dev-eks" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.sg_id]
  }
}

resource "aws_eks_node_group" "dev-eks" {
  cluster_name    = aws_eks_cluster.dev-eks.name
  node_group_name = "${var.env}-spot-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = var.subnet_ids
  capacity_type   = "SPOT"
  instance_types  = var.node_instance_types

  remote_access {
    ec2_ssh_key              = var.key_name
    source_security_group_ids = [var.sg_id]
  }

  scaling_config {
    desired_size = var.desired_nodes
    min_size     = var.min_nodes
    max_size     = var.max_nodes
  }

  update_config {
    max_unavailable = 1
  }

  tags = {
    Environment = var.env
    Name        = "${var.env}-eks-spot-nodes"
  }
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.env}-eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_role" {
  name = "${var.env}-eks-node-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKSWorkerNodePolicy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEC2ContainerRegistryReadOnly" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "eks_node_AmazonEKS_CNI_Policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}



resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "coredns"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "aws-ebs-csi-driver"
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "metrics-server"
}

resource "aws_eks_addon" "cert_manager" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "Cert-Manager"
}

resource "aws_eks_addon" "aws_eks_pod_identity_agent" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "aws-eks-pod-identity-agent"
}
resource "aws_eks_addon" "external_dns" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "Eternal-DNS"
}
resource "aws_eks_addon" "Node_monitoring_agent" {
  cluster_name = aws_eks_cluster.dev-eks.name
  addon_name   = "node-monitoring-agent"
}