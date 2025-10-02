# ----------------------------
# EKS Cluster
# ----------------------------
resource "aws_eks_cluster" "this" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids         = var.subnet_ids
    security_group_ids = [var.sg_id]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_AmazonEKSClusterPolicy
  ]
}

# ----------------------------
# EKS Node Group
# ----------------------------
resource "aws_eks_node_group" "this" {
  cluster_name    = aws_eks_cluster.this.name
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

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eks_node_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.eks_node_AmazonEKS_CNI_Policy
  ]
}

# ----------------------------
# IAM Roles
# ----------------------------
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

# ----------------------------
# Fetch cluster info dynamically
# ----------------------------
data "aws_eks_cluster" "this" {
  name = aws_eks_cluster.this.name
}

data "aws_iam_openid_connect_provider" "this" {
  url = data.aws_eks_cluster.this.identity[0].oidc[0].issuer
}

# ----------------------------
# External DNS IRSA Role + Policy
# ----------------------------
data "aws_iam_policy_document" "external_dns_assume_role" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.this.arn]
    }
    condition {
      test     = "StringEquals"
      variable = "${replace(data.aws_iam_openid_connect_provider.this.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:external-dns"]
    }
  }
}

resource "aws_iam_role" "external_dns_irsa_role" {
  name               = "${var.env}-external-dns-irsa-role"
  assume_role_policy = data.aws_iam_policy_document.external_dns_assume_role.json
}

resource "aws_iam_policy" "external_dns_policy" {
  name        = "${var.env}-external-dns-policy"
  description = "Policy for ExternalDNS to manage Route53 records"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:ListHostedZones",
          "route53:GetChange"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "external_dns_attach" {
  role       = aws_iam_role.external_dns_irsa_role.name
  policy_arn = aws_iam_policy.external_dns_policy.arn
}

# ----------------------------
# EKS Addons (with depends_on)
# ----------------------------
resource "aws_eks_addon" "coredns" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "coredns"
  addon_version = "v1.12.4-eksbuild.1"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "kube-proxy"
  addon_version = "v1.33.3-eksbuild.6"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "vpc-cni"
  addon_version = "v1.20.1-eksbuild.3"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "cert_manager" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "cert-manager"
  addon_version = "v1.18.2-eksbuild.2"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "aws_eks_pod_identity_agent" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "aws-eks-pod-identity-agent"
  addon_version = "v1.3.8-eksbuild.2"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "external_dns" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "external-dns"
  addon_version            = "v0.19.0-eksbuild.2"
  service_account_role_arn = aws_iam_role.external_dns_irsa_role.arn

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this,
    aws_iam_role.external_dns_irsa_role,
    aws_iam_role_policy_attachment.external_dns_attach
  ]
}

resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "metrics-server"
  addon_version = "v0.8.0-eksbuild.1"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "node_monitoring_agent" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "node-monitoring-agent"
  addon_version = "v1.4.0-eksbuild.2"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name  = aws_eks_cluster.this.name
  addon_name    = "aws-ebs-csi-driver"
  addon_version = "v1.47.0-eksbuild.1"

  depends_on = [
    aws_eks_cluster.this,
    aws_eks_node_group.this
  ]
}
