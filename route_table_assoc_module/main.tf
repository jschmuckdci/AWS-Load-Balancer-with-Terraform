resource "aws_route_table_association" "this" {
    subnet_id = var.sub_id
    route_table_id = var.rt_id
}