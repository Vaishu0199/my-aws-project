provider "aws" {
  region = "eu-west-2"  # AWS region
}

# Create a VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "main-vpc"
  }
}

# Create public subnets
resource "aws_subnet" "public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "eu-west-2a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "eu-west-2b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-2"
  }
}

# Create an internet gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "main-igw"
  }
}

# Create a route table and route
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "public-route-table"
  }
}

# Associate the route table with the public subnets
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

# Create a security group
resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

# Launch an EC2 instance
resource "aws_instance" "t2_micro" {
  ami           = "ami-0226b5ec3281d5d20"  
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_1.id

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name = "my-app-keypair"

  tags = {
    Name = "example-instance"
  }
}

# Create an RDS instance
resource "aws_db_instance" "my_db" {
  identifier        = "my-database"
  instance_class    = "db.t3.micro" 
  engine            = "mysql"
  engine_version    = "8.0.32"  
  db_name           = "mydatabase"
  username          = "admin"
  password          = "password123" 
  allocated_storage = 20
  db_subnet_group_name = aws_db_subnet_group.main.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  tags = {
    Name = "my-database"
  }

  publicly_accessible = true
}

# Create a DB subnet group
resource "aws_db_subnet_group" "main" {
  name       = "my-db-subnet-group"
  subnet_ids  = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  tags = {
    Name = "my-db-subnet-group"
  }
}

