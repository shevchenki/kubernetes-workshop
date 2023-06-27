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

variable "vpc_id" {
  description = "The VPC of the Project"
  type        = string
}

variable "eks_control_plane_sg" {
  description = "The security group of the EKS Cluster."
  type        = string
}

# variable "worker_machine_sg" {
#   description = "The sercurity group of the Worker Machine."
#   type        = string
# }

# ================================================================================= #
# Resource
# ================================================================================= #
# --------------------------------------------------------------------- #
# ALB Backend SecurityGroup
# --------------------------------------------------------------------- #
resource "aws_security_group" "alb_backend_sg" {
  name        = "${var.prefix}_alb_backend"
  description = "Security group for Backend"
  vpc_id      = var.vpc_id
  ingress {
    description = "Allow User to ALB Ingress 80 access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.eks_control_plane_sg]
    description     = "Allow the ALB Ingress to communicate with worker"
  }
  tags = {
    Name = "${var.prefix}_alb_backend"
  }
}

# --------------------------------------------------------------------- #
# ALB Backend SecurityGroup Ingress - EKSControlPlaneSecurityGroup
# --------------------------------------------------------------------- #
resource "aws_security_group_rule" "alb_backend_sg" {
  depends_on = [
    aws_security_group.alb_backend_sg,
  ]
  type                     = "ingress"
  description              = "Allow node to communicate ALB Ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  source_security_group_id = aws_security_group.alb_backend_sg.id
  security_group_id        = var.eks_control_plane_sg
}

# # --------------------------------------------------------------------- #
# # ALB Backend SecurityGroup Ingress - worker_machine_sg
# # --------------------------------------------------------------------- #
# resource "aws_security_group_rule" "worker_machine_sg" {
#   depends_on = [
#     aws_security_group.alb_backend_sg,
#   ]
#   type                     = "ingress"
#   description              = "Allow WorkerMachine to communicate Node"
#   from_port                = 0
#   to_port                  = 0
#   protocol                 = "-1"
#   source_security_group_id = var.worker_machine_sg
#   security_group_id        = var.eks_control_plane_sg
# }

# # ================================================================================= #
# # Reource Output
# # ================================================================================= #
# output "alb_backend_sg" {
#   description = "Security groups attached to the ALB Ingress"
#   value       = aws_security_group.alb_backend_sg.id
# }
