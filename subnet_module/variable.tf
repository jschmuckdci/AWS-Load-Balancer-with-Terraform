variable "vpc" {
  type = string
  description = "VPC ID"
}

variable "cidr_block" {
  type = string
  description = "CIDR block for the subnet"
}

variable "map_public_on_launch" {
  type = bool
  description = "Map a public IP on launch for public subnet"
  default = false
}

variable  "name" {
  type = string
  description = "Name of the subnet"
  default = "public"
}

variable "availability_zone" {
  type = string
  description = "Availability zone for the subnet"
}
