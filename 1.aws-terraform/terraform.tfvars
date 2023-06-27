# -------------------------------------------------------- #
# prefix variable
# -------------------------------------------------------- #
prefix = "sandbox"

# -------------------------------------------------------- #
# Aws Region
# -------------------------------------------------------- #
aws_region = "ap-northeast-1"

# -------------------------------------------------------- #
# Availability Zone
# -------------------------------------------------------- #
availability_zone_names = [
  "ap-northeast-1a",
  "ap-northeast-1c"
]

# -------------------------------------------------------- #
# Network
# -------------------------------------------------------- #
vpc_cird               = "10.0.0.0/16"
public_subnet_cidrs01  = "10.0.1.0/24"
public_subnet_cidrs02  = "10.0.2.0/24"
private_subnet_cidrs01 = "10.0.3.0/24"
private_subnet_cidrs02 = "10.0.4.0/24"

# -------------------------------------------------------- #
# Worker Machine
# -------------------------------------------------------- #
worker_machine_subnet_block  = "10.0.64.0/24"
worker_machine_instance_type = "t3.small"
worker_machine_ami_id        = "ami-08a8688fb7eacb171"
worker_machine_key_name      = ""

# -------------------------------------------------------- #
# EKS Cluster
# -------------------------------------------------------- #
eks_version = "1.24"

# -------------------------------------------------------- #
# EKS Node Groups
# -------------------------------------------------------- #
ami_type                = "AL2_x86_64"
node_instance_type      = "t3.small"
node_instance_key_name  = "sagyo_server_key"
node_group_min_size     = "2"
node_group_desired_size = "2"
node_group_max_size     = "2"
node_volume_size        = "20"
