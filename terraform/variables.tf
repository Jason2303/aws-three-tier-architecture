variable "aws_region"{
  type = string
  default = "us-east-1"
}

variable "db_username" {
  type = string
}

variable "web_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_instance_type" {
  type    = string
  default = "t3.micro"
}

variable "acm_certificate_arn" {
  type        = string
  description = "ARN of an ACM certificate for the external ALB's HTTPS listener. Requires a validated domain — not provisioned in this assignment."
  default     = ""
}