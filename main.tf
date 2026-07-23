# 1. Generate the key pair
resource "tls_private_key" "keypair2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Register the public key with AWS
resource "aws_key_pair" "keypair2" {
  key_name   = "ce13-kh-keypair2"
  public_key = tls_private_key.keypair2.public_key_openssh
}

# 3. Save the private key locally so you can SSH in
resource "local_file" "private_key" {
  content         = tls_private_key.keypair2.private_key_pem
  filename        = "C:/Users/kuoho/Documents/NTU PACE/Module 2/18Jul26Coaching/ce13-kh-keypair2.pem"
  file_permission = "0600"
}



resource "aws_instance" "public" {
  ami                         = "ami-01edba92f9036f76e" # find the AMI ID of Amazon Linux 2023
  instance_type               = "t2.micro"
  subnet_id                   = "subnet-07fe08d5909e677db"  #Public Subnet ID, e.g. subnet-xxxxxxxxxxx
  associate_public_ip_address = true
  #key_name                    = "ce13-kh-keypair" #Change to your keyname, e.g. jazeel-key-pair
  key_name                    = aws_key_pair.keypair2.key_name
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
 
  tags = {
    Name = "ce13-kh-ec2"    #Prefix your own name, e.g. jazeel-ec2
  }
}

resource "aws_security_group" "allow_ssh" {
  name        = "ce13-kh-terraform-ec2-sg" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  vpc_id      = "vpc-071dc429d54e64259"  #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
}

resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"  
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}
