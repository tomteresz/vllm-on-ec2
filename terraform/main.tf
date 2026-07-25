#start coding

#thevpc
resource "aws_vpc" "main-vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"

  tags = {
    "Name" = "${local.env_name}"
  }
}

#dhcp options
resource "aws_vpc_dhcp_options" "myaws-lab-dhcp" {
  domain_name_servers = ["AmazonProvidedDNS"]

  tags = {
    "Name" = "myaws.lab"
  }
}

#dhcp options association with vpc
resource "aws_vpc_dhcp_options_association" "myaws-lab-dhcp-dns" {
  vpc_id          = aws_vpc.main-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.myaws-lab-dhcp.id
}

#create-public-subnet
resource "aws_subnet" "main-subnet-public1-eu-central-1a" {
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = "192.168.100.0/27"

  tags = {
    "Name" = "main-subnet-public1-eu-central-1a"
  }
}

#create-public-subnet
resource "aws_subnet" "main-subnet-public2-eu-central-1b" {
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = "192.168.100.32/27"

  tags = {
    "Name" = "main-subnet-public2-eu-central-1b"
  }
}

#create-public-subnet
resource "aws_subnet" "main-subnet-public3-eu-central-1c" {
  vpc_id     = aws_vpc.main-vpc.id
  cidr_block = "192.168.100.64/27"

  tags = {
    "Name" = "main-subnet-public3-eu-central-1c"
  }
}

#create-private-subnet-1a
resource "aws_subnet" "main-subnet-private1-eu-central-1a" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "192.168.100.96/27"
  availability_zone = "eu-central-1a"

  tags = {
    "Name" = "main-subnet-private1-eu-central-1a"
  }
}

#create-private-subnet-1b
resource "aws_subnet" "main-subnet-private2-eu-central-1b" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "192.168.100.128/27"
  availability_zone = "eu-central-1b"

  tags = {
    "Name" = "main-subnet-private2-eu-central-1b"
  }
}

#create-private-subnet-1c
resource "aws_subnet" "main-subnet-private3-eu-central-1c" {
  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = "192.168.100.160/27"
  availability_zone = "eu-central-1c"

  tags = {
    "Name" = "main-subnet-private3-eu-central-1c"
  }
}

#main-route-table
resource "aws_route_table" "default" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    "Name" = "default"
  }
}

#public-route-table
resource "aws_route_table" "main-rtb-public" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    "Name" = "main-rtb-public"
  }
}

#private-route-table-1
resource "aws_route_table" "main-rtb-private1-eu-central-1a" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    "Name" = "main-rtb-private1-eu-central-1a"
  }
}

#private-route-table-2
resource "aws_route_table" "main-rtb-private2-eu-central-1b" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    "Name" = "main-rtb-private2-eu-central-1b"
  }
}

#private-route-table-3
resource "aws_route_table" "main-rtb-private3-eu-central-1c" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.vpc-nat.id
  }

  tags = {
    "Name" = "main-rtb-private3-eu-central-1c"
  }
}

#subnet-association-with-route-table-private
resource "aws_route_table_association" "main-rtb-private1-eu-central-1a" {
  subnet_id      = aws_subnet.main-subnet-private1-eu-central-1a.id
  route_table_id = aws_route_table.main-rtb-private1-eu-central-1a.id
}

#subnet-association-with-route-table-private
resource "aws_route_table_association" "main-rtb-private2-eu-central-1b" {
  subnet_id      = aws_subnet.main-subnet-private2-eu-central-1b.id
  route_table_id = aws_route_table.main-rtb-private2-eu-central-1b.id
}

#subnet-association-with-route-table-private
resource "aws_route_table_association" "main-rtb-private3-eu-central-1c" {
  subnet_id      = aws_subnet.main-subnet-private3-eu-central-1c.id
  route_table_id = aws_route_table.main-rtb-private3-eu-central-1c.id
}

#subnet-association-with-route-table-public
resource "aws_route_table_association" "main-rtb-public" {
  subnet_id      = aws_subnet.main-subnet-public1-eu-central-1a.id
  route_table_id = aws_route_table.main-rtb-public.id
}

#subnet-association-with-route-table-public
resource "aws_route_table_association" "main-rtb-public-2" {
  subnet_id      = aws_subnet.main-subnet-public2-eu-central-1b.id
  route_table_id = aws_route_table.main-rtb-public.id
}

#subnet-association-with-route-table-public
resource "aws_route_table_association" "main-rtb-public-3" {
  subnet_id      = aws_subnet.main-subnet-public3-eu-central-1c.id
  route_table_id = aws_route_table.main-rtb-public.id
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_nat_gateway" "vpc-nat" {
  vpc_id            = aws_vpc.main-vpc.id
  availability_mode = "regional"
  depends_on        = [aws_internet_gateway.main-igw]
  tags = {
    Name = "${local.env_name}-nat"
  }
}

data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}


# 1. IAM Role - trust policy allows EC2 to assume it
resource "aws_iam_role" "test_gpu_ec2_role" {
  name = "test_gpu_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 2. Attach your policy to the role
resource "aws_iam_role_policy_attachment" "test_gpu_ec2_policy" {
  role       = aws_iam_role.test_gpu_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy" # your created policy
}

# 3. Instance profile - the "container" EC2 actually uses
resource "aws_iam_instance_profile" "test_gpu_ec2_profile" {
  name = "test_gpu_ec2_profile"
  role = aws_iam_role.test_gpu_ec2_role.name
}


#ec2
resource "aws_instance" "test_gpu_ec2" {
  instance_type               = "g4dn.xlarge"
  ami                         = "ami-066684246476b7b50"
  subnet_id                   = aws_subnet.main-subnet-public1-eu-central-1a.id
  associate_public_ip_address = true
  key_name                    = "ff-ec2-key"
  iam_instance_profile        = aws_iam_instance_profile.test_gpu_ec2_profile.name

  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  instance_market_options {
    market_type = "spot"

    spot_options {
      instance_interruption_behavior = "terminate"
      spot_instance_type             = "one-time"


    }
  }

  vpc_security_group_ids = [
    aws_security_group.access_sg.id
  ]

  user_data = file("${path.module}/userdata.sh")


  tags = {
    "Name"  = "dev-gpu-node"
    "owner" = "TT"
    "env"   = "${local.env_name}"
    "gpu"   = "yes"
  }
}