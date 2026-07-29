# 1.0 Generate the key pair
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 1.1 Register the public key with AWS
resource "aws_key_pair" "keypair" {
  key_name   = "ce13-kh-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}

# 1.2 Save the private key locally so you can SSH in
resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "C:/Users/kuoho/Documents/NTU PACE/Github_DailyWalk/ce13-kh-keypair.pem"
  file_permission = "0600"
}

# 2.0 Generate EC2 Instance
resource "aws_instance" "public" {
  ami                         = "ami-01edba92f9036f76e" # find the AMI ID of Amazon Linux 2023
  instance_type               = "t2.micro"
  #iam_instance_profile        = aws_iam_instance_profile.dynamodb_read_profile.name
  #subnet_id                  = "subnet-07fe08d5909e677db"  #Public Subnet ID, e.g. subnet-xxxxxxxxxxx
  subnet_id                   = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
 
  tags = {
    Name = "ce13-kh-ec2"    #Prefix your own name, e.g. jazeel-ec2
  }
}

# 2.1 Generate Security Group for EC2 Instance
resource "aws_security_group" "allow_ssh" {
  name        = "ce13-kh-terraform-ec2-sg" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  #vpc_id     = "vpc-071dc429d54e64259"  #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
  vpc_id      = aws_vpc.main.id 

  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# 2.2 Generate Ingress Rule for Security Group
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"  
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# 2.3 Generate VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "ce13-kh-vpc"
  }
}

# 2.4 Generate Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # adjust to your region
  map_public_ip_on_launch = true

  tags = {
    Name = "ce13-kh-public-subnet"
  }
}

# 2.5 Generate Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "ce13-kh-internet-gateway"
  }
}


# 2.6 Generate Route Table with route to IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "ce13-kh-public-rt"
  }
}

# 2.7 Associate route table with subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 3.0 Generate EBS Volume and Attach to EC2 Instance
# EBS volume must be in the SAME AZ as the instance/subnet
resource "aws_ebs_volume" "extra" {
  availability_zone = aws_instance.public.availability_zone
  size              = 1 # GB
  type              = "gp3"

  tags = {
    Name = "ce13-kh-ebs-volume"
  }
}

resource "aws_volume_attachment" "extra_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.extra.id
  instance_id = aws_instance.public.id
}

