output "vpc_id" {
  value = aws_vpc.main_vpc.id
}

output "db_subnet_ids" {
  value = [aws_subnet.db_az1.id, aws_subnet.db_az1.id]
}

output "public_subnet_ids" {
  value = [aws_subnet.public_az1.id, aws_subnet.public_az2.id]
}

output "private_web_subnet_ids" {
  value = [aws_subnet.web1.id, aws_subnet.web2.id]
}

output "private_app_subnet_ids" {
  value = [aws_subnet.app1.id, aws_subnet.app2.id]
}