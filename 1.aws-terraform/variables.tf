# -------------------------------------------------------- #
# prefix variable
# -------------------------------------------------------- #
variable "prefix" {
  type    = string
  default = "sandbox"
}

# -------------------------------------------------------- #
# Aws Region
# -------------------------------------------------------- #
variable "aws_region" {
  description = "aws region"
  default     = "ap-northeast-1"
}

# -------------------------------------------------------- #
# Availability Zone
# -------------------------------------------------------- #
variable "availability_zone_names" {
  type = list(string)
  default = [
    "ap-northeast-1a",
    "ap-northeast-1c"
  ]
}

# -------------------------------------------------------- #
# Network
# -------------------------------------------------------- #
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

# -------------------------------------------------------- #
# Worker Machine
# -------------------------------------------------------- #
variable "worker_machine_subnet_block" {
  type        = string
  default     = "10.0.64.0/24"
  description = "CidrBlock for WorkerMachine Subnet"
}

variable "worker_machine_instance_type" {
  type    = string
  default = "t3.small"
}

variable "worker_machine_ami_id" {
  type    = string
  default = "ami-08a8688fb7eacb171"
}

variable "worker_machine_key_name" {
  description = "KeyPair Name (Optional)"
  default     = ""
  type        = string
}

# -------------------------------------------------------- #
# EKS Cluster
# -------------------------------------------------------- #
variable "eks_version" {
  description = "EKS Version"
  default     = "1.25"
  type        = string
}


# -------------------------------------------------------- #
# EKS Node Groups
# -------------------------------------------------------- #
variable "ami_type" {
  description = "AL2_x86_64 | AL2_x86_64_GPU"
  default     = "AL2_x86_64"
  type        = string
}

variable "node_instance_type" {
  type    = string
  default = "t3.medium"
}

variable "node_instance_key_name" {
  type    = string
  default = "SagyouServerKey"
}

variable "node_group_min_size" {
  type        = number
  description = "Minimum size of Node Group."
  default     = "2"
}

variable "node_group_desired_size" {
  type        = number
  description = "Desired size of Node Group."
  default     = "2"
}

variable "node_group_max_size" {
  type        = number
  description = "Maximum size of Node Group."
  default     = "3"
}

variable "node_volume_size" {
  type        = number
  description = "Node volume size"
  default     = 30
}
