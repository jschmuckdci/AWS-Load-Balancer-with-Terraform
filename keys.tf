#nginx keys autoscaling keys
resource "tls_private_key" "asg_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "asg_key" {
  key_name   = "asg-key"
  public_key = tls_private_key.asg_key.public_key_openssh
}

resource "local_file" "asg_key_pem" {
  content         = tls_private_key.asg_key.private_key_pem
  filename        = "${path.module}/asg-key.pem"
  file_permission = "0600"
}

#bastion key
resource "tls_private_key" "bastion_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "bastion_key" {
  key_name   = "bastion-key"
  public_key = tls_private_key.bastion_key.public_key_openssh
}

resource "local_file" "bastion_key_pem" {
  content  = tls_private_key.bastion_key.private_key_pem
  filename = "${path.module}/bastion-key.pem"

  # Set appropriate permissions to 600
  file_permission = "0600"
}