# main.tf en root/

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

# Configuración de datos de la VPC
data "aws_vpc" "default" {
  default = true
}

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Llamada al módulo ECS
module "ecs" {
  source = "../module/ecs"

  cluster_name = "nginx-cluster"
  task_cpu     = "256"
  task_memory  = "512"
  nginx_image  = "nginx:latest"
  vpc_id       = data.aws_vpc.default.id
  subnets      = data.aws_subnet_ids.default.ids
  desired_count = 1
}