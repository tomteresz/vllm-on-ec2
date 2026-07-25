resource "aws_security_group" "access_sg" {
  name        = "test-gpu-all-inbound"
  description = "LAB ONLY - Allow all inbound and outbound traffic"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description = "LAB ONLY - all inbound IPv4 traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp" # All protocols
    cidr_blocks = [local.my_ip_cidr]
  }


  egress {
    description = "Allow all outbound IPv4 traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # All protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "test-gpu-all-inbound"
    env       = "${local.env_name}"
    temporary = "true"
  }
}