# ================================================================================= #
# Reource Input
# ================================================================================= #
variable "prefix" {
  type    = string
  default = ""
}

variable "aws_region" {
  description = "aws region"
  default     = "ap-northeast-1"
}

variable "availability_zone_names" {
  type = list(string)
  default = [
    "ap-northeast-1a",
    "ap-northeast-1c"
  ]
}

variable "vpc_cird" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidrs01" {
  type    = string
  default = "10.0.1.0/24"
}

variable "public_subnet_cidrs02" {
  type    = string
  default = "10.0.2.0/24"
}

variable "private_subnet_cidrs01" {
  type    = string
  default = "10.0.3.0/24"
}

variable "private_subnet_cidrs02" {
  type    = string
  default = "10.0.4.0/24"
}

variable "worker_machine_subnet_block" {
  type        = string
  default     = "10.0.64.0/24"
  description = "CidrBlock for WorkerMachine Subnet"
}

# ================================================================================= #
# Resource EKS
# ================================================================================= #
# --------------------------------------------------------------------- #
# VPC
# --------------------------------------------------------------------- #
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cird
  enable_dns_support   = true
  enable_dns_hostnames = true
  enable_classiclink   = false
  instance_tenancy     = "default"
  tags = {
    Name = "${var.prefix}_vpc"
  }
}

# --------------------------------------------------------------------- #
# Internet Gateway
# --------------------------------------------------------------------- #
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}_igw"
  }
}

# --------------------------------------------------------------------- #
# Public Subnet
# --------------------------------------------------------------------- #
resource "aws_subnet" "public_subnet01" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone_names[0]
  cidr_block              = var.public_subnet_cidrs01
  map_public_ip_on_launch = true
  tags = {
    Name                                              = "${var.prefix}_pub_sn_01"
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${var.prefix}_eks_cluster" = "owned"
  }
}
resource "aws_subnet" "public_subnet02" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.availability_zone_names[1]
  cidr_block              = var.public_subnet_cidrs02
  map_public_ip_on_launch = true
  tags = {
    Name                                              = "${var.prefix}_pub_sn_02"
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/${var.prefix}_eks_cluster" = "owned"
  }
}

# --------------------------------------------------------------------- #
# Public Route Table
# --------------------------------------------------------------------- #
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}_pub_route_table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# --------------------------------------------------------------------- #
# Route Table Association
# --------------------------------------------------------------------- #
resource "aws_route_table_association" "pubic_subnet01_associate" {
  subnet_id      = aws_subnet.public_subnet01.id
  route_table_id = aws_route_table.public_route_table.id
}
resource "aws_route_table_association" "pubic_subnet02_associate" {
  subnet_id      = aws_subnet.public_subnet02.id
  route_table_id = aws_route_table.public_route_table.id
}

# --------------------------------------------------------------------- #
# Elastic IP
# --------------------------------------------------------------------- #
resource "aws_eip" "nat_gateway_elastic_ip01" {
  vpc = true
  tags = {
    Name = "${var.prefix}_ngw_eip_01"
  }
}
resource "aws_eip" "nat_gateway_elastic_ip02" {
  vpc = true
  tags = {
    Name = "${var.prefix}_ngw_eip_02"
  }
}

# --------------------------------------------------------------------- #
# Nat Gateway
# --------------------------------------------------------------------- #
resource "aws_nat_gateway" "nat_gateway_01" {
  allocation_id = aws_eip.nat_gateway_elastic_ip01.id
  subnet_id     = aws_subnet.public_subnet01.id
}
resource "aws_nat_gateway" "nat_gateway_02" {
  allocation_id = aws_eip.nat_gateway_elastic_ip02.id
  subnet_id     = aws_subnet.public_subnet02.id
}

# --------------------------------------------------------------------- #
# Private Subnet
# --------------------------------------------------------------------- #
resource "aws_subnet" "private_subnet01" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zone_names[0]
  cidr_block        = var.private_subnet_cidrs01
  tags = {
    Name                                              = "${var.prefix}_pri_sn_01"
    "kubernetes.io/cluster/${var.prefix}_eks_cluster" = "owned"
    "kubernetes.io/role/internal-elb"                 = "1"
  }
}
resource "aws_subnet" "private_subnet02" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = var.availability_zone_names[1]
  cidr_block        = var.private_subnet_cidrs02
  tags = {
    Name                                              = "${var.prefix}_pri_sn_01"
    "kubernetes.io/cluster/${var.prefix}_eks_cluster" = "owned"
    "kubernetes.io/role/internal-elb"                 = "1"
  }
}

# --------------------------------------------------------------------- #
# Private Route Table
# --------------------------------------------------------------------- #
resource "aws_route_table" "private_route_table01" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}_pri_route_table_01"
  }
}

# Route to NAT Gateway
resource "aws_route" "private_route01" {
  route_table_id         = aws_route_table.private_route_table01.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_01.id
}

resource "aws_route_table" "private_route_table02" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "${var.prefix}_pri_route_table_02"
  }
}

# Route to NAT Gateway
resource "aws_route" "private_route02" {
  route_table_id         = aws_route_table.private_route_table02.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway_02.id
}

# --------------------------------------------------------------------- #
# Route Table Association
# --------------------------------------------------------------------- #
resource "aws_route_table_association" "private_subnet01_associate" {
  subnet_id      = aws_subnet.private_subnet01.id
  route_table_id = aws_route_table.private_route_table01.id
}
resource "aws_route_table_association" "private_subnet02_associate" {
  subnet_id      = aws_subnet.private_subnet02.id
  route_table_id = aws_route_table.private_route_table02.id
}

# # ================================================================================= #
# # Resource VPC Endpoint
# # ================================================================================= #
# # --------------------------------------------------------------------- #
# # VPC Endpoint SecurityGroup
# # --------------------------------------------------------------------- #
# resource "aws_security_group" "vpc_endpoint_sg" {
#   name        = "${var.prefix}_vpc_endpoint_sg"
#   description = "VPC Endpoint Security Group"
#   vpc_id      = aws_vpc.vpc.id
#   ingress {
#     description = "TLS from VPC"
#     from_port   = 443
#     to_port     = 443
#     protocol    = "tcp"
#     cidr_blocks = [
#       var.vpc_cird
#     ]
#   }

#   tags = {
#     Name = "${var.prefix}_vpc_endpoint_sg"
#   }
# }

# # --------------------------------------------------------------------- #
# # sts VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "sts" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.sts"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_sts"
#   }
# }

# # --------------------------------------------------------------------- #
# # Ec2Messages VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "ec2_messages" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.ec2messages"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_ec2messages"
#   }
# }

# # --------------------------------------------------------------------- #
# # S3 VPC Endpoint
# # Does Not Support PrivateDnsEnabled
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "s3" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.s3"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   tags = {
#     Name = "${var.prefix}_s3"
#   }
# }

# # --------------------------------------------------------------------- #
# # Ssm VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "ssm" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.ssm"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_ssm"
#   }
# }

# # --------------------------------------------------------------------- #
# # SsmMessages VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "ssm_messages" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.ssmmessages"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_ssmmessages"
#   }
# }

# # --------------------------------------------------------------------- #
# # Autoscaling VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "autoscaling" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.autoscaling"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_autoscaling"
#   }
# }

# # --------------------------------------------------------------------- #
# # Ebs VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "ebs" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.ebs"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_ebs"
#   }
# }

# # --------------------------------------------------------------------- #
# # Kms VPC Endpoint
# # --------------------------------------------------------------------- #
# resource "aws_vpc_endpoint" "kms" {
#   vpc_id            = aws_vpc.vpc.id
#   service_name      = "com.amazonaws.${var.aws_region}.kms"
#   vpc_endpoint_type = "Interface"

#   security_group_ids = [
#     aws_security_group.vpc_endpoint_sg.id,
#   ]

#   subnet_ids = [
#     aws_subnet.public_subnet01.id,
#     aws_subnet.public_subnet02.id
#   ]

#   private_dns_enabled = true

#   tags = {
#     Name = "${var.prefix}_kms"
#   }
# }

# # ================================================================================= #
# # Resource Worker Machine
# # ================================================================================= #
# # --------------------------------------------------------------------- #
# # WorkerMachine Subnet
# # --------------------------------------------------------------------- #
# resource "aws_subnet" "worker_machine_subnet" {
#   vpc_id                  = aws_vpc.vpc.id
#   availability_zone       = var.availability_zone_names[0]
#   cidr_block              = var.worker_machine_subnet_block
#   map_public_ip_on_launch = true
#   tags = {
#     Name                              = "${var.prefix}_worker_machine_sn"
#     "kubernetes.io/role/internal-elb" = "1"
#   }
# }

# # --------------------------------------------------------------------- #
# # Route Table Association
# # --------------------------------------------------------------------- #
# resource "aws_route_table_association" "worker_machine_subnet_route_table_association" {
#   subnet_id      = aws_subnet.worker_machine_subnet.id
#   route_table_id = aws_route_table.public_route_table.id
# }

# ================================================================================= #
# Reource Output
# ================================================================================= #
# VPC ID
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.vpc.id
}

# Public Subnet ID
output "public_subnet01" {
  description = "Public Subnet 01 ID"
  value       = aws_subnet.public_subnet01.id
}
output "public_subnet02" {
  description = "Public Subnet 02 ID"
  value       = aws_subnet.public_subnet02.id
}

# Private Subnet ID
output "private_subnet01" {
  description = "Private Subnet 01 ID"
  value       = aws_subnet.private_subnet01.id
}
output "private_subnet02" {
  description = "Private Subnet 02 ID"
  value       = aws_subnet.private_subnet02.id
}

# # Worker Machine Subnet ID
# output "worker_machine_subnet" {
#   description = "Worker Machine Subnet ID"
#   value       = aws_subnet.worker_machine_subnet.id
# }
