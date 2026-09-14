#Launch Template for Web
resource "aws_launch_template" "ec2_launch_template" {
  name_prefix   = "${var.name}-lt-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  vpc_security_group_ids = [var.security_group_id]

  tags = {
    Name = "${var.name}-launch-template"
  }
}

#Autoscaling Group
resource "aws_autoscaling_group" "ec2_asg" {
  name                = "${var.name}-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = var.target_group_arns    

  launch_template {
    id      = aws_launch_template.ec2_launch_template.id
    version = "$Latest"
  }

  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  tag {
    key                 = "Name"
    value               = var.name
    propagate_at_launch = true
  }
}

#AMI 
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

#IAM Role to Access the RDS PostgreSQL DB
resource "aws_iam_role" "instance_role" {
  name = "${var.name}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.name}-instance-role"
  }
}

#IAM Role Policy
resource "aws_iam_role_policy" "secrets_access" {
  count = var.db_secret_arn != "" ? 1 : 0

  name = "${var.name}-secrets-access"
  role = aws_iam_role.instance_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "secretsmanager:GetSecretValue"
      Resource = var.db_secret_arn
    }]
  })
}

#IAM Instance Profile for the EC2 Instance
resource "aws_iam_instance_profile" "instance_profile" {
  name = "${var.name}-instance-profile"
  role = aws_iam_role.instance_role.name
}

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
