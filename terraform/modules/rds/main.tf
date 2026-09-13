#RDS Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds_db_subnet_group"
  subnet_ids = var.db_subnet_ids
  

  tags = {
    Name = "RDS DB subnet group"
  }
}

#RDS Instance
resource "aws_db_instance" "rds" {
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "postgres"
  engine_version       = "16.15"
  instance_class       = "db.t3.micro"
  username             = var.db_username
  parameter_group_name = "default.postgres16"
  skip_final_snapshot  = true
  multi_az = true
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [var.db_sg_id]
  storage_encrypted = true
  manage_master_user_password = true
}