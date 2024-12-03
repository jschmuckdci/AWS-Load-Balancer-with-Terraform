variable "vpc" {
  type = string
  description = "vpc id"
}

variable "internet_gateway" {
    type = string
    description = "ig for public route table"
    default = null #ignored by terraform during creation if null
}

variable "nat_gateway" {
  type = string
  description = "nat gateway for private route table"
  default = null #ignored by terraform during creation if null
}

variable "name" {
  type = string
  description = "name of the route table"
  default = "route_table"
}