# outputs.tf en module/ecs

output "nginx_lb_dns_name" {
  description = "DNS name for Nginx Load Balancer"
  value       = aws_lb.nginx_lb.dns_name
}