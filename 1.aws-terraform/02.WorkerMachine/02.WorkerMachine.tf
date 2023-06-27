# ================================================================================= #
# Reource Input
# ================================================================================= #
variable "prefix" {
  type    = string
  default = "pre"
}
variable "aws_region" {
  description = "aws region"
  default     = "ap-northeast-1"
}
variable "vpc_id" {
  description = "The VPC of the worker instances"
  type        = string
}
variable "worker_machine_subnet" {
  description = "WorkerMachine Subnet ID"
  type        = string
}
variable "worker_machine_instance_type" {
  type    = string
  default = "t3.small"
}
variable "worker_machine_ami_id" {
  type    = string
  default = "ami-0278fe6949f6b1a06"
}
variable "worker_machine_key_name" {
  description = "KeyPair Name (Optional)"
  default     = ""
  type        = string
}

# ================================================================================= #
# Resource WorkerMachine
# ================================================================================= #
# --------------------------------------------------------------------- #
# WorkerMachine SecurityGroup
# --------------------------------------------------------------------- #
resource "aws_security_group" "worker_machine_sg" {
  name        = "${var.prefix}_worker_machine_sg"
  description = "WorkerMachine Security Group"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.prefix}_worker_machine_sg"
  }
}

# --------------------------------------------------------------------- #
# WorkerMachine SSM Role
# --------------------------------------------------------------------- #
resource "aws_iam_role" "ssm_role_for_ec2" {
  name = "ssm_role_for_ec2"
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
  path = "/"
}

resource "aws_iam_role_policy_attachment" "ssm_role_for_ec2_attach_ssm_policy" {
  role       = aws_iam_role.ssm_role_for_ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_policy" "eks_node_group_policies" {
  name = "${var.prefix}_worker_machine_access_eks"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "eks:DescribeCluster"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_role_for_ec2-attach-eks_node_group_policies" {
  role       = aws_iam_role.ssm_role_for_ec2.name
  policy_arn = aws_iam_policy.eks_node_group_policies.arn
}

# --------------------------------------------------------------------- #
# WorkerMachine InstanceProfile
# --------------------------------------------------------------------- #
resource "aws_iam_instance_profile" "ssm_instance_profile" {
  name = "ssm_instance_profile"
  role = aws_iam_role.ssm_role_for_ec2.name
}

# --------------------------------------------------------------------- #
# WorkerMachine
# --------------------------------------------------------------------- #
resource "aws_instance" "worker_machine" {
  ami                    = var.worker_machine_ami_id
  instance_type          = var.worker_machine_instance_type
  subnet_id              = var.worker_machine_subnet
  vpc_security_group_ids = [aws_security_group.worker_machine_sg.id]
  key_name               = var.worker_machine_key_name
  root_block_device {
    encrypted             = true
    volume_size           = 20
    volume_type           = "gp3"
    delete_on_termination = true
  }
  iam_instance_profile = aws_iam_instance_profile.ssm_instance_profile.id
  tags = {
    Name = "${var.prefix}_worker_machine"
  }
}

# --------------------------------------------------------------------- #
# Policy To Add UserGroup
# --------------------------------------------------------------------- #
resource "aws_iam_policy" "worker_machine_ssm_access_policy" {
  depends_on = [
    aws_instance.worker_machine
  ]
  name        = "${var.prefix}_worker_machine_access_ssm"
  description = "policy to allow SSM access to WorkServer"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "ssm:StartSession"
        Effect   = "Allow"
        Resource = aws_instance.worker_machine.arn
      },
      {
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:ssm:*:*:session/$${aws.username}-*"
      },
    ]
  })
}

# ================================================================================= #
# Reource Output
# ================================================================================= #
output "worker_machine_sg" {
  description = "SG For WorkerMachine"
  value       = aws_security_group.worker_machine_sg.id
}
output "worker_machine_role_arn" {
  value = aws_iam_role.ssm_role_for_ec2.arn
}

output "worker_machine_ssm_access_policy" {
  description = "Policy to access WorkerMachine by SSM"
  value       = aws_iam_policy.worker_machine_ssm_access_policy.arn
}
