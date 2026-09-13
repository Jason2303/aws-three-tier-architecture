# Availability Zone 1
variable "availability_zone" {
    type = list(string)
    default = ["us-east-1a", "us-east-1b"]  
}

variable "route" {
    type = string
    default = "0.0.0.0/0"
}
