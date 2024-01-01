# variables.tf en module/ecs

variable "cluster_name" {
  description = "Nombre del cluster de ECS."
  type        = string
}

variable "task_cpu" {
  description = "La cantidad de CPU para la task definition."
  default     = "256"
}

variable "task_memory" {
  description = "La cantidad de memoria para la task definition."
  default     = "512"
}

variable "nginx_image" {
  description = "La imagen de Docker para el contenedor de Nginx."
  default     = "nginx:latest"
}

variable "vpc_id" {
  description = "El ID de la VPC donde se desplegará el ECS."
  type        = string
}

variable "subnets" {
  description = "Las subnets para el Load Balancer y el servicio ECS."
  type        = list(string)
}

variable "desired_count" {
  description = "El número deseado de instancias de la tarea."
  default     = 1
}