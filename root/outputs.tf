# outputs.tf en root/

output "nginx_lb_dns_name" {
  description = "DNS name for Nginx Load Balancer"
  value       = module.ecs.nginx_lb_dns_name
}