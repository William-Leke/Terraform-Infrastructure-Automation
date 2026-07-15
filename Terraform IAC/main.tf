# A complete AWS environment with Terraform

# create a VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "main_vpc"
    environment = var.environment
  }
}

# Create NACL for public subnets 
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "public_nacl"
    environment = var.environment
  }
}

# create a public subnet 1
resource "aws_subnet" "public_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_1_cidr
  availability_zone = var.availability_zone[0]
  tags = {
    Name = "public_subnet_1"
    environment = var.environment
  }
}

# Create Private Subnet 1
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_1_cidr
  availability_zone = var.availability_zone[0]
  tags = {
    Name = "private_subnet_1"
    environment = var.environment
  }
}
# create a public subnet 2
resource "aws_subnet" "public_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_2_cidr
  availability_zone = var.availability_zone[1]
  tags = {
    Name = "public_subnet_2"
    environment = var.environment
  }
}

# create a private subnet 2
resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_2_cidr
  availability_zone = var.availability_zone[1]
  tags = {
    Name = "private_subnet_2"
    environment = var.environment
  }
}

# create an internet gateway
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = {
    Name = "wl-iac_igw"
  }
}


# create an Elastic IP for the NAT gateway 1
resource "aws_eip" "nat_eip1" {
  domain = "vpc"
  tags = {
    Name = "wl-iac_nat_eip1"
  }
}
# create a NAT gateway for private subnets in public subnet 1
resource "aws_nat_gateway" "NAT_GW1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "wl-iac_nat_gw1"
    environment = var.environment
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency 
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main_igw]
}

# create an Elastic IP for the NAT gateway 2
resource "aws_eip" "nat_eip2" {
  domain = "vpc"
  tags = {
    Name = "wl-iac_nat_eip2"
    environment = var.environment
  }
}

# create a NAT gateway for private subnets in public subnet 2
resource "aws_nat_gateway" "NAT_GW2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = aws_subnet.public_subnet_2.id

  tags = {
    Name = "wl-iac_nat_gw2"
    environment = var.environment
  }
  # To ensure proper ordering, it is recommended to add an explicit dependency 
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main_igw]
}

# create security group for the EC2 instances
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2_security_group"
  description = "Least privilege security group for EC2 instances"
  vpc_id      = aws_vpc.main_vpc.id

  # no inbound ssh from the internet, only from the public subnets

  egress { # egress means outbound traffic from the EC2 instances to the internet
    description = "Allow all outbound traffic (Via NAT gateway)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ec2_security_group"
    environment = var.environment
  }
}
# create ec2 instance in private subnet 1
resource "aws_instance" "private_instance_1" {
  ami                    = data.aws_ami.ec2_instance_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  tags = {
    Name = "private_instance_1"
    environment = var.environment
  }
}

# create ec2 instance in private subnet 2
resource "aws_instance" "private_instance_2" {
  ami                    = data.aws_ami.ec2_instance_ami.id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet_2.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  tags = {
    Name = "private_instance_2"
    environment = var.environment
  }
}

# Create An S3 bucket for logging/backups, with versioning enabled
resource "aws_s3_bucket" "my_bucket" {
  bucket = "wl-versioning-bucket-${var.environment}"

  tags = {
    Name        = "wl-versioning-bucket"
    environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "my_bucket_versioning" {
  bucket = aws_s3_bucket.my_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Bucket policy to allow logging and backups from the VPC to the S3 bucket
resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = aws_s3_bucket.my_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::755283537660:user/William_Admin"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.my_bucket.arn}/*"
      }
    ]
  })
}





