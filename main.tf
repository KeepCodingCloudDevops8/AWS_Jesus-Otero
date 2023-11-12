terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"  // Asegúrate de usar la versión más adecuada para tu configuración.
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

resource "aws_ecs_cluster" "nginx_cluster" {
  name = "nginx-cluster"
}

# Crear un IAM Role para la ejecución de ECS Tasks
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

# Adjuntar la política de ejecución de ECS al rol
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Definir la Task Definition de ECS para nginx
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn

  container_definitions = jsonencode([{
    name  = "nginx",
    image = "nginx:latest",
    essential = true,
    portMappings = [{
      containerPort = 80,
      hostPort      = 80
    }]
  }])
}

# Crear un Security Group para el Load Balancer que permita tráfico HTTP
resource "aws_security_group" "nginx_alb_sg" {
  name        = "nginx-alb-sg"
  description = "Security Group for Nginx ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Definir la configuración del Load Balancer
resource "aws_lb" "nginx_lb" {
  name               = "nginx-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.nginx_alb_sg.id]
  subnets            = data.aws_subnet_ids.default.ids
}

# Definir el grupo objetivo del Load Balancer
resource "aws_lb_target_group" "nginx_tg" {
  name     = "nginx-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id
  target_type = "ip"
}

# Definir el Listener del Load Balancer
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = aws_lb.nginx_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_tg.arn
  }
}

# Crear el servicio ECS que usará la Task Definition de nginx
resource "aws_ecs_service" "nginx_service" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.nginx_cluster.id
  task_definition = aws_ecs_task_definition.nginx_task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = data.aws_subnet_ids.default.ids
    security_groups = [aws_security_group.nginx_alb_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
}

# Utilizar datos de la VPC por defecto
data "aws_vpc" "default" {
  default = true
}

# Utilizar datos de las subnets por defecto
data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

# Configurar el output para el endpoint del Load Balancer
output "nginx_lb_dns_name" {
  description = "DNS name for Nginx Load Balancer"
  value       = aws_lb.nginx_lb.dns_name
}