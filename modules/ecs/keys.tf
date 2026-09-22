# Create a Key Pair (Private Key)
resource "tls_private_key" "ecs-asg" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ecs-asg"
  public_key = tls_private_key.ecs-asg.public_key_openssh
}

resource "local_file" "ecs-asg" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.ecs-asg.private_key_pem
}
