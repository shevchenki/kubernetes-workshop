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

variable "key_name" {
  description = "The EC2 Key Pair to allow SSH access to the instances"
  type        = string
}

variable "ami_type" {
  description = "AL2_x86_64 | AL2_x86_64_GPU"
  default     = "AL2_x86_64"
  type        = string
}

variable "node_instance_type" {
  type    = string
  default = "t3.small"
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum size of Node Group."
  default     = 1
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired size of Node Group."
  default     = 2
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum size of Node Group."
  default     = 3
}

variable "node_volume_size" {
  type        = number
  description = "Node volume size"
  default     = 20
}

variable "eks_cluster_name" {
  description = "EKS Cluster Name"
  type        = string
}

variable "node_subnets" {
  description = "The subnets where workers can be created."
  type        = list(string)
}

# # ================================================================================= #
# # Resource
# # ================================================================================= #
# # --------------------------------------------------------------------- #
# # EKS Node Group Policy
# # --------------------------------------------------------------------- #
# resource "aws_iam_policy" "eks_node_group_policies" {
#   name = "${var.prefix}_eks_node_group"
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "autoscaling:DescribeAutoScalingGroups",
#           "autoscaling:DescribeAutoScalingInstances",
#           "autoscaling:DescribeLaunchConfigurations",
#           "autoscaling:DescribeTags",
#           "autoscaling:SetDesiredCapacity",
#           "autoscaling:TerminateInstanceInAutoScalingGroup",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action = [
#           "kms:Decrypt",
#           "kms:Encrypt",
#           "kms:GenerateDataKey",
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       }
#     ]
#   })
# }

# --------------------------------------------------------------------- #
# EKS Node Group Role
# --------------------------------------------------------------------- #
resource "aws_iam_role" "eks_node_group_role" {
  name = "${var.prefix}_eks_node_group"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    # aws_iam_policy.eks_node_group_policies.arn
  ]
}

# --------------------------------------------------------------------- #
# EKS Node Group InstanceProfile
# --------------------------------------------------------------------- #
resource "aws_iam_instance_profile" "eks_node_group_instance_profile" {
  name = "EKSNodeGroupInstanceProfile"
  role = aws_iam_role.eks_node_group_role.name
}

# --------------------------------------------------------------------- #
# EKS Node Group LaunchTemplate UserData
# --------------------------------------------------------------------- #
data "template_file" "eks_node_group_launch_template" {
  template = <<EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="

--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"

#!/bin/bash

yum install -y amazon-ssm-agent
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

--==MYBOUNDARY==--\
EOF
}

# --------------------------------------------------------------------- #
# EKS Node Group LaunchTemplate
# --------------------------------------------------------------------- #
resource "aws_launch_template" "eks_node_group_launch_template" {
  name = "${var.prefix}_eks_node_group"

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.node_volume_size
      encrypted   = true
      volume_type = "gp3"
    }
  }
  instance_type = var.node_instance_type
  key_name      = var.key_name
  user_data     = base64encode(data.template_file.eks_node_group_launch_template.rendered)

}

# --------------------------------------------------------------------- #
# EKS Node Group
# --------------------------------------------------------------------- #
resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = var.eks_cluster_name
  node_group_name = "${var.prefix}_eks_node_group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
  subnet_ids      = var.node_subnets
  ami_type        = var.ami_type
  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }
  launch_template {
    id      = aws_launch_template.eks_node_group_launch_template.id
    version = aws_launch_template.eks_node_group_launch_template.latest_version
  }
}

# ================================================================================= #
# Reource Output
# ================================================================================= #
output "eks_node_group_role_arn" {
  value = aws_iam_role.eks_node_group_role.arn
}
output "eks_node_group_name" {
  #EKS Cluster name and EKS Node Group name separated by a colon (:).
  value = aws_eks_node_group.eks_node_group.id
}
