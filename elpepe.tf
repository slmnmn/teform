provider "aws" {
  region = "us-east-1"
}


##Networking and vpc
resource "aws_vpc" "lavpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Prueba terraform"
  }

}

resource "aws_subnet" "hola" {
    vpc_id = aws_vpc.lavpc.id
    cidr_block = "10.0.1.0/24"

    tags = {
      Name = "public subnet"
    }
}


resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lavpc.id

  tags = {
    Name = "IG de la VPC"
  }
}

#Route table association.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lavpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "public-rt"
  }
}


resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.hola.id
  route_table_id = aws_route_table.public.id
}

## Security groups

resource "aws_security_group" "allow_80" {
  name        = "allow_http"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.lavpc.id

  tags = {
    Name = "allow_http"
  }
}


resource "aws_vpc_security_group_ingress_rule" "allow_http_ipv4" {
  security_group_id = aws_security_group.allow_80.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  security_group_id = aws_security_group.allow_80.id
  description = "Allow all outbound traffic"

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}


#instance

resource "aws_instance" "testing" {
    ami = "ami-0b245cc5f82576748"
    instance_type = "t3.micro"
    subnet_id = aws_subnet.hola.id

    iam_instance_profile = "InstanceRole-SSM"

    vpc_security_group_ids = [aws_security_group.allow_80.id]



    user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y || yum update -y
              dnf install -y httpd || yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello World from Apache</h1>" > /var/www/html/index.html
              EOF
  )

    associate_public_ip_address = true


  tags = {
    Name = "SSM-Managed-Instance"
  }
}


