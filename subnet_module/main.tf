resource "aws_subnet" "this" {
    vpc_id = var.vpc
    cidr_block = var.cidr_block
    map_public_ip_on_launch = var.map_public_on_launch
    availability_zone = var.availability_zone
    tags = {
        Name = var.name
    }
}