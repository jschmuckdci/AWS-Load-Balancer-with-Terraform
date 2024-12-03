provider "aws" {
  region = "us-west-2"
}

#Get ip for bastion security group. 
#This method will cause issues with provisioning pipeline tools.
data "http" "my_ip" {
  url = "https://api.ipify.org?format=text"
}

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "My-VPC"
  }
}

module "public_subnet_az2a" {
  source               = "./subnet_module"
  vpc                  = aws_vpc.my-vpc.id
  cidr_block           = "10.0.1.0/24"
  availability_zone    = "us-west-2a"
  map_public_on_launch = true
  name                 = "public-az2a"
}

module "private_subnet_az2a" {
  source            = "./subnet_module"
  vpc               = aws_vpc.my-vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2a"
  map_public_on_launch = false
  name                 = "private-az2a"
}

module "private_subnet_az2b" {
  source            = "./subnet_module"
  vpc               = aws_vpc.my-vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-west-2b"
  map_public_on_launch = false
  name                 = "private-az2b"
}

module "public_subnet_az2b" {
  source               = "./subnet_module"
  vpc                  = aws_vpc.my-vpc.id
  cidr_block           = "10.0.4.0/24"
  availability_zone    = "us-west-2b"
  map_public_on_launch = true
  name                 = "public-az2b"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "Internet-Gateway"
  }
}

#create EIPs for NAT Gateways
resource "aws_eip" "nat_eip_az2a" {
  vpc = true 
}

resource "aws_eip" "nat_eip_az2b" {
  vpc = true 
}

#NAT gateway is used to allow instances in private subnet to access internet
resource "aws_nat_gateway" "nat_az2a" {
  allocation_id = aws_eip.nat_eip_az2a.id
  subnet_id     = module.public_subnet_az2a.subnet_id

  tags = {
    Name = "NAT-Gateway-az2a"
  }
}

resource "aws_nat_gateway" "nat_az2b" {
  allocation_id = aws_eip.nat_eip_az2b.id
  subnet_id     = module.public_subnet_az2b.subnet_id

  tags = {
    Name = "NAT-Gateway-az2b"
  }
}

#create public and private route tables
module "public_route_table_az2a" {
  source           = "./route_table_module"
  vpc              = aws_vpc.my-vpc.id
  internet_gateway = aws_internet_gateway.igw.id
  name             = "public route table az2a"
}

module "public_route_table_az2b" {
  source           = "./route_table_module"
  vpc              = aws_vpc.my-vpc.id
  internet_gateway = aws_internet_gateway.igw.id
  name             = "public route table az2b"
}

module "private_route_table_az2a" {
  source      = "./route_table_module"
  vpc         = aws_vpc.my-vpc.id
  nat_gateway = aws_nat_gateway.nat_az2a.id
  name        = "private route table az2a"
}

module "private_route_table_az2b" {
  source      = "./route_table_module"
  vpc         = aws_vpc.my-vpc.id
  nat_gateway = aws_nat_gateway.nat_az2b.id
  name        = "private route table az2b"
}

#associate the route tables with the subnets
module "public_subnet_association_az2a" {
  source = "./route_table_assoc_module"
  sub_id = module.public_subnet_az2a.subnet_id
  rt_id  = module.public_route_table_az2a.my_rt_id
}

module "public_subnet_association_az2b" {
  source = "./route_table_assoc_module"
  sub_id = module.public_subnet_az2b.subnet_id
  rt_id  = module.public_route_table_az2b.my_rt_id
}

module "private_subnet_association_az2a" {
  source = "./route_table_assoc_module"
  sub_id = module.private_subnet_az2a.subnet_id
  rt_id  = module.private_route_table_az2a.my_rt_id
}

module "private_subnet_association_az2b" {
  source = "./route_table_assoc_module"
  sub_id = module.private_subnet_az2b.subnet_id
  rt_id  = module.private_route_table_az2b.my_rt_id
}

#launch template defines the configuration of the instances
resource "aws_launch_template" "nginx" {
  name_prefix            = "nginx-server-"
  image_id               = "ami-04dd23e62ed049936"
  instance_type          = "t2.micro"
  user_data              = base64encode(file("user-data.sh"))
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]
  key_name               = aws_key_pair.asg_key.key_name

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "nginx-server"
    }
  }
}

#autoscaling group defines the configuration of the autoscaling group
resource "aws_autoscaling_group" "nginx" {
  vpc_zone_identifier = [module.private_subnet_az2a.subnet_id, module.private_subnet_az2b.subnet_id]
  desired_capacity    = 2
  max_size            = 4
  min_size            = 2
  launch_template {
    id      = aws_launch_template.nginx.id
    version = aws_launch_template.nginx.latest_version
  }

  tag {
    key                 = "Name"
    value               = "nginx-server"
    propagate_at_launch = true
  }
}

#Application Load Balancer - routes traffic at the application layer
resource "aws_lb" "nginx" {
  name               = "nginx-lb"
  load_balancer_type = "application"
  internal           = false
  security_groups    = [aws_security_group.lb_sg.id]
  subnets            = [module.public_subnet_az2a.subnet_id, module.public_subnet_az2b.subnet_id]
}

#listener specifies how to handle requests to port 80
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = aws_lb.nginx.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target.arn
  }
}

#target group defines the collection of instances the lb sends traffic to
resource "aws_lb_target_group" "nginx_target" {
  name     = "nginx-target"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my-vpc.id
}

resource "aws_autoscaling_attachment" "nginx" {
  autoscaling_group_name = aws_autoscaling_group.nginx.id
  lb_target_group_arn    = aws_lb_target_group.nginx_target.arn
}

#Bastion host instance 
resource "aws_instance" "bastion" {
  ami                    = "ami-04dd23e62ed049936" # Replace with a valid Linux AMI ID for your region
  instance_type          = "t2.micro"
  subnet_id              = module.public_subnet_az2a.subnet_id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.bastion_key.key_name

  provisioner "file" {
    source = "asg-key.pem"
    destination = "/home/ubuntu/asg-key.pem"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo chmod 600 /home/ubuntu/asg-key.pem"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = local_file.bastion_key_pem.content
    host        = self.public_ip
  } 

  tags = {
    Name = "BastionHost"
  }
}

