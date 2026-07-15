
############################# VPC NETWORKING ###################################################
# create a route table for public subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = "public_route_table"
  }
}

# associate the public route table with the public subnet 1
resource "aws_route_table_association" "public_subnet_1_association" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_route_table.id
}

# associate the public route table with the public subnet 2
resource "aws_route_table_association" "public_subnet_2_association" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# create private route table for AZ1 private subnet to route traffic through NAT_GW1
resource "aws_route_table" "private_route_table_az1" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GW1.id
  }
  tags = {
    Name = "private_route_table_az1"
  }
}

# create private route table for AZ2 private subnet to route traffic through NAT_GW2
resource "aws_route_table" "private_route_table_az2" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_GW2.id
  }
  tags = {
    Name = "private_route_table_az2"
  }
}

# associate the private route table with the private subnet 1
resource "aws_route_table_association" "private_subnet_1_association" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_route_table_az1.id
}

# associate the private route table with the private subnet 2
resource "aws_route_table_association" "private_subnet_2_association" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table_az2.id
}

# associate the public NACL with the public subnet 1
resource "aws_network_acl_association" "main" {
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = aws_subnet.public_subnet_1.id
}

# associate the public NACL with the public subnet 2
resource "aws_network_acl_association" "main2" {
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = aws_subnet.public_subnet_2.id
}