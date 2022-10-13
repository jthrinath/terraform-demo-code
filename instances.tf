# creating ec2 instances

resource "aws_instance" "webapp-1" {
  ami           = "ami-062df10d14676e201"
  key_name      = "linux-machine-on-aws-1"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1a.id
  vpc_security_group_ids = [aws_security_group.allow_80-22.id]
# security_groups= ["security_demo_port"]
tags = {
    Name = "webapp-1"
    App  = "frontend"
    Technical-owner = "Thrinath"
  }
}

resource "aws_instance" "webapp-2" {
  ami           = "ami-062df10d14676e201"
  key_name      = "linux-machine-on-aws-1"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.mysubnet-1b.id
  vpc_security_group_ids = [aws_security_group.allow_80-22.id]
# security_groups= ["security_demo_port"]

tags = {
    Name = "webapp-2"
    App  = "frontend"
    Technical-owner = "Thrinath"
  }
}