# create a vpc with the limited IP range 10.0.0.0/16
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}


# create a gateway resource and attaches it to main_vpc
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}


# create a route table resource and adds all outbound traffic to the gateway
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}


# create a subnet with the limited IP range 10.0.1.0/24
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name = "public_subnet"
  }
}


# associate the subnet with the route table
resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# create a security group (inbound port 80, outbound all)
resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP inbound and all outbound"
  vpc_id      = aws_vpc.main_vpc.id

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
    Name = "web_sg"
  }
}


# create an elastic network interface ENI in the subnet
resource "aws_network_interface" "web_eni" {
  subnet_id   = aws_subnet.public_subnet.id
  private_ips = ["10.0.1.50"]
  security_groups = [
    aws_security_group.web_sg.id
  ]

  tags = {
    Name = "web_eni"
  }
}


# create the elastic IP and attach it to the ENI private IP
resource "aws_eip" "web_eip" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web_eni.id
  associate_with_private_ip = "10.0.1.50"

  depends_on = [
    aws_instance.web_server,
    aws_network_interface.web_eni
  ]
}


# create EC2 instance with ubuntu image (running apache web server) 
resource "aws_instance" "web_server" {
  ami           = "ami-0b0ea68c435eb488d" # Ubuntu 22.04 (example)
  instance_type = "t2.micro"

  primary_network_interface {
    # device_index         = 0
    network_interface_id = aws_network_interface.web_eni.id
  }

  user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y apache2
             sudo systemctl start apache2
             sudo systemctl enable apache2
             echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
             EOF

  tags = {
    Name = "WebServerInstance"
  }
}


# creates a debug output with public IP
output "public_ip" {
  value       = aws_eip.web_eip.public_ip
  description = "Public IP of the web server"
}