#External ALB SG
resource "aws_security_group" "external_alb_sg" {
  name        = "allow_external_traffic_to_alb"
  description = "Allow HTTP & HTTPS inbound traffic from internet to external ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_traffic_in"
  }
}

#Ingress Rule for Port 443
resource "aws_vpc_security_group_ingress_rule" "alb_allow_https" {
  security_group_id = aws_security_group.external_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

#Ingress Rule for Port 80
resource "aws_vpc_security_group_ingress_rule" "alb_allow_http" {
  security_group_id = aws_security_group.external_alb_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

#Egress rule for external ALB responses
resource "aws_vpc_security_group_egress_rule" "alb_allow_responses" {
  security_group_id            = aws_security_group.external_alb_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id
  from_port                     = 80
  to_port                       = 80
  ip_protocol                   = "tcp"
}


#Web SG
resource "aws_security_group" "web_sg" {
  name        = "allow_external_traffic_from_alb"
  description = "Allow traffic from internet from external ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_traffic_from_external_ALB"
  }
}

#Ingress Rule for Web SG
resource "aws_vpc_security_group_ingress_rule" "web_allow_from_external_alb" {
  security_group_id = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.external_alb_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

#Egress rule for traffic to internal ALB 
resource "aws_vpc_security_group_egress_rule" "web_to_internal_alb" {
  security_group_id            = aws_security_group.web_sg.id
  referenced_security_group_id = aws_security_group.internal_alb_sg.id
  from_port                     = 80
  to_port                       = 80
  ip_protocol                   = "tcp"
}


#Internal ALB SG
resource "aws_security_group" "internal_alb_sg" {
  name        = "allow_traffic_from_web"
  description = "Allow traffic from web"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_traffic_from_web"
  }
}

#Ingress Rule for Web SG
resource "aws_vpc_security_group_ingress_rule" "internal_alb_allow_from_web" {
  security_group_id = aws_security_group.internal_alb_sg.id
  referenced_security_group_id = aws_security_group.web_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


#Egress rule for traffic from internal ALB to App 
resource "aws_vpc_security_group_egress_rule" "internal_alb_to_app" {
  security_group_id            = aws_security_group.internal_alb_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port                     = 80
  to_port                       = 80
  ip_protocol                   = "tcp"
}


#App SG
resource "aws_security_group" "app_sg" {
  name        = "allow_traffic_from_internal_alb"
  description = "Allow traffic from interal ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_traffic_from_internal_ALB"
  }
}

#Ingress Rule for App SG
resource "aws_vpc_security_group_ingress_rule" "app_allow_from_internal_alb" {
  security_group_id = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.internal_alb_sg.id
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}


#Egress rule for traffic to DB
resource "aws_vpc_security_group_egress_rule" "app_to_db" {
  security_group_id            = aws_security_group.app_sg.id
  referenced_security_group_id = aws_security_group.db_sg.id
  from_port                     = 5432
  to_port                       = 5432
  ip_protocol                   = "tcp"
}


#DB SG
resource "aws_security_group" "db_sg" {
  name        = "allow_traffic_from_app"
  description = "Allow traffic from App"
  vpc_id      = var.vpc_id

  tags = {
    Name = "allow_traffic_from_App"
  }
}

#Ingress Rule for DB SG
resource "aws_vpc_security_group_ingress_rule" "db_allow_from_app" {
  security_group_id = aws_security_group.db_sg.id
  referenced_security_group_id = aws_security_group.app_sg.id
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

#Web Updates
resource "aws_vpc_security_group_egress_rule" "web_allow_os_updates" {
  security_group_id = aws_security_group.web_sg.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 443
  to_port            = 443
  ip_protocol        = "tcp"
}

#App Updates
resource "aws_vpc_security_group_egress_rule" "app_allow_os_updates" {
  security_group_id = aws_security_group.app_sg.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = 443
  to_port            = 443
  ip_protocol        = "tcp"
}