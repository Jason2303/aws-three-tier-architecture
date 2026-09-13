variable "acm_certificate_arn" {
  type        = string
}

variable "external_alb_sg_id" {
  type = string
}

variable "internal_alb_sg_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_web_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}
