# resource for security group
resource "aws_security_group" "web_sg" {
  name        = "web_security_group"
  description = "Allow inbound HTTP traffic and outbound all traffic"

  # inbound rule http 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # accessible from anywhere
  }

  # outbound rule for all traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # all protocols
    cidr_blocks = ["0.0.0.0/0"]  # allow all outbound traffic
  }
}

# resource for EC2 instance
resource "aws_instance" "web_server" {
  ami                    = "ami-0b0ea68c435eb488d"  # ubuntu AMI ID for EC2
  instance_type          = "t2.micro" 
  associate_public_ip_address = true 
  key_name               = "swarm" 

  # security group attachment for the instance
  security_groups = [aws_security_group.web_sg.name]

  # user data script to install apache web server and display "Hello World"
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

# output to display the public DNS address of the instance
output "instance_public_dns" {
  value = aws_instance.web_server.public_dns  
  description = "The public DNS of the web server EC2 instance"
}