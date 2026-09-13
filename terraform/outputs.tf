output "vpc_id" {
  value = module.networking.vpc_id
}

output "external_alb_dns_name" {
  value = module.alb.external_alb_dns_name
}

output "rds_endpoint" {
  value = module.rds.rds_endpoint
}

output "db_secret_arn" {
  value = module.rds.db_secret_arn
}