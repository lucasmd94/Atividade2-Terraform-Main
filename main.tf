resource "aws_vpc" "vpc" {
  cidr_block           = "10.11.0.0/16"
  enable_dns_hostnames = true
  tags = {
   Name = "vpc-${var.module_name}"
 }
}

resource "aws_internet_gateway" "internet_gateway" {
 vpc_id = aws_vpc.vpc.id
 tags = {
   Name = "internet-gateway-${var.module_name}"
 }
}

data "aws_availability_zones" "availability" {}

resource "aws_subnet" "public_subnet" {
    count = 2
    vpc_id            = aws_vpc.vpc.id
    cidr_block = "10.11.${10+count.index}.0/24"
    availability_zone = "${data.aws_availability_zones.availability.names[count.index]}"
    map_public_ip_on_launch = true
    
    tags = {
        Name = "public-subnet-${var.module_name}"
    }
}

resource "aws_subnet" "private_subnet" {
    count = 2
    vpc_id            = aws_vpc.vpc.id
    cidr_block = "10.11.${20+count.index}.0/24"
    availability_zone = "${data.aws_availability_zones.availability.names[count.index]}"
    map_public_ip_on_launch = false
    
    tags = {
        Name = "private-subnet-${var.module_name}}"
    }
}

resource "aws_security_group" "server_security_group" {
  name        = "${var.module_name}-SecurityGroup"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = "80"
    to_port     = "80"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = "0"
    protocol    = "-1"
    to_port     = "0"
  }

  tags = {
    "Name" = "${var.module_name}-server-security-group"
  }
}

module "ec2" {
  source = "git::https://github.com/lucasmd94/Atividade2-Terraform-EC2"

  region = var.region
  ami = "ami-00c39f71452c08778"
  instance_type = "t3.micro"
  subnet_id = aws_subnet.private_subnet[0].id
  instance_name = var.module_name
  security_group_id = aws_security_group.server_security_group.id
}

module "rds" {
  source = "git::https://github.com/lucasmd94/Atividade2-Terraform-RDS"

  region = var.region
  security_group_id = aws_security_group.server_security_group.id
  db_name = "db"
  identifier = "db-instance-main"
  engine = "postgres"
  engine_version = "12"
  instance_class = "db.t3.micro"
  storage_size = 5
  username = "dbadmin"
  password = "adm0@"
  subnet_group_name_list = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]
}

module "sqs" {
  source = "git::https://github.com/lucasmd94/Atividade2-Terraform-SQS"

  region = var.region
  queue_name = var.module_name
}