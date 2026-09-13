# Create the VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

#Create Public Subnet AZ1 for NAT GW
resource "aws_subnet" "public_az1" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[0]
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "az1"
  }
}

#Create Public Subnet AZ2 for NAT GW
resource "aws_subnet" "public_az2" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[1]
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "az2"
  }
}

#Create Web Private Subnet
resource "aws_subnet" "web1" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[0]
  cidr_block = "10.0.11.0/24"

  tags = {
    Name = "private_web_az1"
  }
}

#Create Web Private Subnet
resource "aws_subnet" "web2" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[1]
  cidr_block = "10.0.12.0/24"

  tags = {
    Name = "private_web_az2"
  }
}

#Create App Private Subnet
resource "aws_subnet" "app1" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[0]
  cidr_block = "10.0.21.0/24"

  tags = {
    Name = "private_app_az1"
  }
}

#Create App Private Subnet
resource "aws_subnet" "app2" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[1]
  cidr_block = "10.0.22.0/24"

  tags = {
    Name = "private_app_az2"
  }
}

#Create DB Private Subnet
resource "aws_subnet" "db_az1" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[0]
  cidr_block = "10.0.31.0/24"

  tags = {
    Name = "private_db_az1"
  }
}

#Create DB Private Subnet
resource "aws_subnet" "db_az2" {
  vpc_id = aws_vpc.main_vpc.id
  availability_zone = var.availability_zone[1]
  cidr_block = "10.0.32.0/24"

  tags = {
    Name = "private_db_az2"
  }
}

#Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id
  depends_on = [ aws_vpc.main_vpc ]

  tags = {
    Name = "IGW"
  }
}

#NAT GW EIP 1
resource "aws_eip" "nat_az1" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-az1"
  }
}

#NAT GW EIP 2
resource "aws_eip" "nat_az2" {
  domain = "vpc"

  tags = {
    Name = "nat-eip-az2"
  }
}

#NAT Gateway 1
resource "aws_nat_gateway" "nat_gateway_1" {
  allocation_id = aws_eip.nat_az1.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "gw_NAT_1"
  }
  depends_on = [aws_internet_gateway.gw]
}

#NAT Gateway 2
resource "aws_nat_gateway" "nat_gateway_2" {
  allocation_id = aws_eip.nat_az2.id
  subnet_id     = aws_subnet.public_az2.id

  tags = {
    Name = "gw_NAT_2"
  }
  depends_on = [aws_internet_gateway.gw]
}

#Public Subnet Route Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.route
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Public_Subnet_for_NAT_GWs"
  }
}

#Private-web & Private-app AZ1 Route Table
resource "aws_route_table" "az1_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.route
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name = "Private_AZ1"
  }
}

#Private-web & Private-app AZ2 Route Table
resource "aws_route_table" "az2_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = var.route
    nat_gateway_id = aws_nat_gateway.nat_gateway_1.id
  }

  tags = {
    Name = "Private_AZ2"
  }
}

#DB Route Table
resource "aws_route_table" "db_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "DB"
  }
}

#Route Table Association for Public Subnet AZ1
resource "aws_route_table_association" "public_subnet_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public_route_table.id
}

#Route Table Association for Public Subnet AZ2
resource "aws_route_table_association" "public_subnet_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public_route_table.id
}

#Route Table Association for Private Subnet Web1
resource "aws_route_table_association" "web_subnet_az1" {
  subnet_id      = aws_subnet.web1.id
  route_table_id = aws_route_table.az1_route_table.id
}

#Route Table Association for Private Subnet Web2
resource "aws_route_table_association" "web_subnet_az2" {
  subnet_id      = aws_subnet.web2.id
  route_table_id = aws_route_table.az2_route_table.id
}

#Route Table Association for Private Subnet App1
resource "aws_route_table_association" "app_subnet_az1" {
  subnet_id      = aws_subnet.app1.id
  route_table_id = aws_route_table.az1_route_table.id
}

#Route Table Association for Private Subnet App2
resource "aws_route_table_association" "app_subnet_az2" {
  subnet_id      = aws_subnet.app2.id
  route_table_id = aws_route_table.az2_route_table.id
}

#Route Table Association for Private Subnet DB1
resource "aws_route_table_association" "app_subnet_db1" {
  subnet_id      = aws_subnet.db_az1.id
  route_table_id = aws_route_table.db_route_table.id
}

#Route Table Association for Private Subnet DB2
resource "aws_route_table_association" "app_subnet_db2" {
  subnet_id      = aws_subnet.db_az2.id
  route_table_id = aws_route_table.db_route_table.id
}