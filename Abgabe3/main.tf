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

resource "aws_instance" "web_servers" {
  count         = 2
  ami           = "ami-0b0ea68c435eb488d"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  user_data = <<-EOF
             #!/bin/bash
             sudo apt-get update
             sudo apt-get install -y apache2
             sudo systemctl start apache2
             sudo systemctl enable apache2
             echo "<h1>Hello World</h1>" | sudo tee /var/www/html/index.html
             EOF

  tags = {
    Name = "WebServer-${count.index}"
  }
}

# Create Load Balancer
resource "aws_lb" "web_lb" {
  name               = "web-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.web_sg.id]
  subnets            = [aws_subnet.public_subnet.id]

  enable_deletion_protection = false
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "WebLoadBalancer"
  }
}

# Create Target Group
resource "aws_lb_target_group" "web_tg" {
  name     = "web-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    interval            = 30
    path                = "/"
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 3
    protocol            = "HTTP"
  }

  tags = {
    Name = "WebTargetGroup"
  }
}

# Register EC2 instances to the Target Group
resource "aws_lb_target_group_attachment" "web_attachment" {
  count            = length(aws_instance.web_servers)
  target_group_arn = aws_lb_target_group.web_tg.arn
  target_id        = aws_instance.web_servers[count.index].id
  port             = 80
}

# Create Listener
resource "aws_lb_listener" "web_listener" {
  load_balancer_arn = aws_lb.web_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_tg.arn
  }
}

# Output the Load Balancer DNS Name
output "lb_dns_name" {
  value = aws_lb.web_lb.dns_name
}
