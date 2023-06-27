locals {
  cidr_blocks_without_class_a = [
    "0.0.0.0/5",
    "8.0.0.0/7",
    "11.0.0.0/8",
    "12.0.0.0/8",
    "13.0.0.0/8",
    "14.0.0.0/8",
    "15.0.0.0/8",
    "16.0.0.0/4",
    "32.0.0.0/3",
    "64.0.0.0/2",
    "128.0.0.0/1",
  ]
}
# ================================================================================= #
# Reource Input
# ================================================================================= #
variable "aws_region" {
  description = "AWS REGION"
  type        = string
  default     = "ap-northeast-1"
}

variable "prefix" {
  description = "Resource name prefix"
  type        = string
  default     = "pre"
}

variable "eks_version" {
  description = "EKS Version"
  default     = "1.24"
  type        = string
}

variable "vpc_id" {
  description = "The VPC of the worker instances"
  type        = string
}

variable "eks_subnets" {
  description = "The private subnets where worker nodes can be created."
  type        = list(string)
}

# ================================================================================= #
# Resource
# ================================================================================= #
data "aws_caller_identity" "current" {}

# --------------------------------------------------------------------- #
# EKS Role
# --------------------------------------------------------------------- #
resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.prefix}_eks_cluster_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role-attach-amazon_eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role-attach-amazon_eks_service_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# --------------------------------------------------------------------- #
# KMS Key
# --------------------------------------------------------------------- #
resource "aws_kms_key" "eks_cluster_key" {
  description = "EKS Cluster Key"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "key-eks",
  "Statement": [
    {
      "Sid": "Enable IAM User Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    }
  ]
}
  POLICY
}

resource "aws_kms_alias" "eks_cluster_key_alias" {
  name          = "alias/${var.prefix}_eks_cluster_key"
  target_key_id = aws_kms_key.eks_cluster_key.key_id
}

# --------------------------------------------------------------------- #
# SG
# --------------------------------------------------------------------- #
resource "aws_security_group" "eks_cluster_control_plane" {
  name        = "${var.prefix}-eks-cluster-control-plane"
  description = "The cluster control plane communication with worker nodes"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.prefix}-eks-cluster-control-plane"
  }
}

# ### Worker Node Security Group for EKS(ServicePlatform)
# resource "aws_security_group" "eks_cluster_worker_node" {
#   name        = "${var.prefix}-eks-cluster-worker-node"
#   description = "Security group for all worker nodes in the cluster"
#   vpc_id      = var.vpc_id

#   tags = {
#     "Name"                                                          = "${var.prefix}-eks-cluster-worker-node"
#     "kubernetes.io/cluster/${var.prefix}-eks-cluster-control-plane" = "owned"
#   }
# }

# resource "aws_security_group_rule" "eks_cluster_control_plane_ingress_from_worker_node" {
#   security_group_id        = aws_security_group.eks_cluster_control_plane.id
#   description              = "Allow worker node to communicate with the cluster control plane"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   type                     = "ingress"
#   source_security_group_id = aws_security_group.eks_cluster_worker_node.id
# }

# resource "aws_security_group_rule" "eks_cluster_control_plane_egress_to_worker_node" {
#   security_group_id        = aws_security_group.eks_cluster_control_plane.id
#   description              = "Allow the cluster control plane to communicate with worker nodes"
#   from_port                = 1025
#   to_port                  = 65535
#   protocol                 = "tcp"
#   type                     = "egress"
#   source_security_group_id = aws_security_group.eks_cluster_worker_node.id
# }

# # From this worker nodes
# resource "aws_security_group_rule" "eks_cluster_worker_node_ingress_from_worker_nodes" {
#   security_group_id        = aws_security_group.eks_cluster_worker_node.id
#   description              = "Allow worker node to communicate with each other"
#   type                     = "ingress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "-1"
#   source_security_group_id = aws_security_group.eks_cluster_worker_node.id
# }

# resource "aws_security_group_rule" "eks_cluster_worker_node_egress_to_worker_nodes" {
#   security_group_id        = aws_security_group.eks_cluster_worker_node.id
#   description              = "Allow worker node to communicate with each other"
#   type                     = "egress"
#   from_port                = 0
#   to_port                  = 65535
#   protocol                 = "-1"
#   source_security_group_id = aws_security_group.eks_cluster_worker_node.id
# }

# # From control plane
# resource "aws_security_group_rule" "eks_cluster_worker_node_ingress_from_control_plane" {
#   security_group_id        = aws_security_group.eks_cluster_worker_node.id
#   description              = "Allow Kubelets and pods to receive communication from the cluster control plane"
#   type                     = "ingress"
#   from_port                = 1025
#   to_port                  = 65535
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.eks_cluster_control_plane.id
# }

# # To endpoint
# resource "aws_security_group_rule" "eks_cluster_worker_node_egress_https_to_vpc" {
#   security_group_id = aws_security_group.eks_cluster_worker_node.id
#   description       = "Allow pods to communicate with endpoints in vpc"
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = ["10.0.0.0/16"]
# }

# resource "aws_security_group_rule" "eks_cluster_worker_node_ingress_https_from_control_plane" {
#   security_group_id        = aws_security_group.eks_cluster_worker_node.id
#   description              = "Allow Kubelets and pods to receive communication from the cluster control plane"
#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.eks_cluster_control_plane.id
# }

# resource "aws_security_group_rule" "eks_cluster_worker_node_to_internet_egress_https" {
#   security_group_id = aws_security_group.eks_cluster_worker_node.id
#   description       = "Allow worker node to communicate with internet"
#   type              = "egress"
#   from_port         = 443
#   to_port           = 443
#   protocol          = "tcp"
#   cidr_blocks       = local.cidr_blocks_without_class_a
# }

# resource "aws_security_group_rule" "eks_cluster_worker_node_to_internet_egress_http" {
#   security_group_id = aws_security_group.eks_cluster_worker_node.id
#   description       = "Allow worker node to communicate with internet"
#   type              = "egress"
#   from_port         = 80
#   to_port           = 80
#   protocol          = "tcp"
#   cidr_blocks       = local.cidr_blocks_without_class_a
# }

# --------------------------------------------------------------------- #
# EKS Cluster
# --------------------------------------------------------------------- #
resource "aws_eks_cluster" "eks_cluster" {
  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role-attach-amazon_eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_role-attach-amazon_eks_service_policy,
  ]

  name     = "${var.prefix}_eks_cluster"
  version  = var.eks_version
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    security_group_ids      = [aws_security_group.eks_cluster_control_plane.id]
    subnet_ids              = var.eks_subnets
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_cluster_key.arn
    }
    resources = ["secrets"]
  }
}

data "tls_certificate" "eks_cluster_oidc_issuer" {
  url = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "service_platform_irsa" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_cluster_oidc_issuer.certificates.0.sha1_fingerprint]
  url             = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

# ================================================================================= #
# Reource Output
# ================================================================================= #
output "eks_sg" {
  description = "EKS Control Plane & WorkerNode Security Group"
  value       = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks_cluster.id
}

# output "eks_cluster_worker_node_sg_id" {
#   description = "EKS Worker Node SG Id"
#   value       = aws_security_group.eks_cluster_worker_node.id
# }
