resource "aws_route_table" "this" {
    vpc_id = var.vpc
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.internet_gateway
        nat_gateway_id =  var.nat_gateway
    }
    tags = {
        Name = var.name
    }
}

