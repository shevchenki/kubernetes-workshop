# Setting Provider - AWS with terraform version 3.0
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "sandbox-env"
}

# Netowk Resource
module "Network" {
  source                      = "./01.Network/"
  prefix                      = var.prefix
  aws_region                  = var.aws_region
  availability_zone_names     = var.availability_zone_names
  vpc_cird                    = var.vpc_cird
  public_subnet_cidrs01       = var.public_subnet_cidrs01
  public_subnet_cidrs02       = var.public_subnet_cidrs02
  private_subnet_cidrs01      = var.private_subnet_cidrs01
  private_subnet_cidrs02      = var.private_subnet_cidrs02
  worker_machine_subnet_block = var.worker_machine_subnet_block
}

# # WorkerMachine
# module "WorkerMachine" {
#   source                       = "./02.WorkerMachine/"
#   prefix                       = var.prefix
#   aws_region                   = var.aws_region
#   vpc_id                       = module.Network.vpc_id
#   worker_machine_subnet        = module.Network.worker_machine_subnet
#   worker_machine_instance_type = var.worker_machine_instance_type
#   worker_machine_ami_id        = var.worker_machine_ami_id
#   worker_machine_key_name      = var.worker_machine_key_name
# }

# EKS Cluster
module "Eks-Cluster" {
  source     = "./03.EksCluster/"
  aws_region = var.aws_region
  prefix     = var.prefix
  vpc_id     = module.Network.vpc_id
  eks_subnets = [
    module.Network.private_subnet01,
    module.Network.private_subnet02,
  ]
  eks_version = var.eks_version
}

# EKS NodeGroups
module "Eks-NodeGroups" {
  source           = "./04.EksNodeGroup/"
  aws_region       = var.aws_region
  prefix           = var.prefix
  eks_cluster_name = module.Eks-Cluster.eks_cluster_name
  node_subnets = [
    module.Network.private_subnet01,
    module.Network.private_subnet02
  ]
  ami_type                = var.ami_type
  key_name                = var.node_instance_key_name
  node_instance_type      = var.node_instance_type
  node_group_min_size     = var.node_group_min_size
  node_group_desired_size = var.node_group_desired_size
  node_group_max_size     = var.node_group_max_size
  node_volume_size        = var.node_volume_size
}

# ALB Backend Security Group
module "Alb-Backend-Security-Group" {
  source               = "./05.SecurityGroup/"
  aws_region           = var.aws_region
  prefix               = var.prefix
  vpc_id               = module.Network.vpc_id
  eks_control_plane_sg = module.Eks-Cluster.eks_sg
  # worker_machine_sg    = module.WorkerMachine.worker_machine_sg
}

# # Ecr
# module "Ecr" {
#   source               = "./06.Ecr/"
#   aws_region           = var.aws_region
#   prefix               = var.prefix
#   image_save_version = "7"
# }
