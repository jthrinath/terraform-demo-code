#
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.33.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# creating new vpc
resource "aws_vpc" "demo-vpc" {
  cidr_block       = "10.10.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "vpc-terraform"
  }
}

# creating new subnets
resource "aws_subnet" "mysubnet-1a" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.10.1.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch= "true"

  tags = {
    Name = "MY-SUBNET-1A"
  }
}

resource "aws_subnet" "mysubnet-1b" {
  vpc_id     = aws_vpc.demo-vpc.id
  cidr_block = "10.10.2.0/24"
  availability_zone = "ap-south-1b"
  map_public_ip_on_launch= "true"

  tags = {
    Name = "MY-SUBNET-1B"
  }
}




# creating internet gw
resource "aws_internet_gateway" "Demo-IG" {
  vpc_id = aws_vpc.demo-vpc.id

  tags = {
    Name = "Demo-IG"
  }
}

# creating Route table

resource "aws_route_table" "webapp-route-table" {
  vpc_id = aws_vpc.demo-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Demo-IG.id
  }

  tags = {
    Name = "webapp-route-table"
  }
}

# creating route table association

resource "aws_route_table_association" "webapp-association-RT-1A" {
  subnet_id      = aws_subnet.mysubnet-1a.id
  route_table_id = aws_route_table.webapp-route-table.id
}

resource "aws_route_table_association" "webapp-association-RT-1B" {
  subnet_id      = aws_subnet.mysubnet-1b.id
  route_table_id = aws_route_table.webapp-route-table.id
}

# creating the target group

resource "aws_lb_target_group" "webapp-lb-target-group" {
  name     = "webapp-lb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.demo-vpc.id
}

# creating LB target group attachment

resource "aws_lb_target_group_attachment" "webapp-lb-target-group-attachment-1" {
  target_group_arn = aws_lb_target_group.webapp-lb-target-group.arn
  target_id        = aws_instance.webapp-1.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "webapp-lb-target-group-attachment-2" {
  target_group_arn = aws_lb_target_group.webapp-lb-target-group.arn
  target_id        = aws_instance.webapp-2.id
    port             = 80
}

# creating load balancer

resource "aws_lb" "webapp-LB" {
  name               = "webapp-LB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_80-for-LB.id]
  subnets            = [aws_subnet.mysubnet-1a.id,aws_subnet.mysubnet-1b.id]

  # enable_deletion_protection = true

  tags = {
    Environment = "production"
  }
}


# creating LB listener

resource "aws_lb_listener" "webapp-LB-listener" {
  load_balancer_arn = aws_lb.webapp-LB.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webapp-lb-target-group.arn
  }
}

# creating AWS autoscalling

resource "aws_launch_template" "webapp-launch-template" {
  name_prefix   = "webapp"
  image_id      = "ami-0ef0447a0b6022df5"
  instance_type = "t2.micro"
  key_name = "linux-machine-on-aws-1"
  vpc_security_group_ids = [aws_security_group.allow_80-22.id]

}

resource "aws_autoscaling_group" "webapp-ASG" {
  # availability_zones = ["ap-south-1a","ap-south-1b"]
  desired_capacity   = 2
  max_size           = 3
  min_size           = 2
  vpc_zone_identifier = [aws_subnet.mysubnet-1a.id,aws_subnet.mysubnet-1b.id]

  launch_template {
    id      = aws_launch_template.webapp-launch-template.id
    version = "$Latest"
  }
}