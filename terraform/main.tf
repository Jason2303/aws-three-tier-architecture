module "networking" {
  source = "./modules/networking"
}

module "security_groups" {
  source = "./modules/security-groups"
  vpc_id = module.networking.vpc_id
}

module "rds" {
  source        = "./modules/rds"
  db_sg_id      = module.security_groups.db_sg_id
  db_subnet_ids = module.networking.db_subnet_ids
  db_username   = var.db_username
}

module "alb" {
  source                  = "./modules/alb"
  vpc_id                  = module.networking.vpc_id
  public_subnet_ids       = module.networking.public_subnet_ids
  private_web_subnet_ids  = module.networking.private_web_subnet_ids
  external_alb_sg_id      = module.security_groups.external_alb_sg_id
  internal_alb_sg_id      = module.security_groups.internal_alb_sg_id
  acm_certificate_arn     = var.acm_certificate_arn
}

module "web_asg" {
  source             = "./modules/asg"
  name               = "web"
  instance_type      = var.web_instance_type
  security_group_id  = module.security_groups.web_sg_id
  subnet_ids         = module.networking.private_web_subnet_ids
  target_group_arns = [module.alb.web_target_group_arn]
}

module "app_asg" {
  source             = "./modules/asg"
  name               = "app"
  instance_type      = var.app_instance_type
  security_group_id  = module.security_groups.app_sg_id
  subnet_ids         = module.networking.private_app_subnet_ids
  target_group_arns = [module.alb.app_target_group_arn]
}

