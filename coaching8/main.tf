locals {
 name_prefix = "ce13-kh-coaching8-iam"
}


resource "aws_iam_role" "role_example" {
 name = "${local.name_prefix}-role-example"


 assume_role_policy = jsonencode({
   Version = "2012-10-17"
   Statement = [
     {
       Action = "sts:AssumeRole"
       Effect = "Allow"
       Sid    = ""
       Principal = {
         Service = "ec2.amazonaws.com"
       }
     },
   ]
 })
}


#data "aws_iam_policy_document" "policy_example" {
# statement {
#   effect    = "Allow"
#   actions   = ["ec2:Describe*"]
#   resources = ["*"]
# }
# statement {
#   effect    = "Allow"
#   actions   = ["s3:ListBucket"]
#   resources = ["*"]
# }
#}

#resource "aws_iam_policy" "policy_example" {
# name = "${local.name_prefix}-policy-example"
#
#
# ## Option 1: Attach data block policy document
# policy = data.aws_iam_policy_document.policy_example.json
#
#
#}


resource "aws_iam_policy" "policy_example" {
  #name        = "ce13-kh-dynamodb-read"
  name = "${local.name_prefix}-policy-example"
  description = "Allows List and Read actions on the book inventory DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "SecretsManagerGetSecretValue"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:us-east-1:255945442255:secret:rds!db-515a72cb-f908-4b3c-9659-8b2df9f33cd7-xUqj5K"
      },
      {
        Sid    = "RDSDescribeActions"
        Effect = "Allow"
        Action = [
          "rds:Describe*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBListActions"
        Effect = "Allow"
        Action = [
          "dynamodb:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBReadActions"
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:Describe*",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:PartiQLSelect",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.book_inventory.arn,
          "${aws_dynamodb_table.book_inventory.arn}/index/*"
        ]
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "attach_example" {
 role       = aws_iam_role.role_example.name
 policy_arn = aws_iam_policy.policy_example.arn
}


resource "aws_iam_instance_profile" "profile_example" {
 name = "${local.name_prefix}-profile-example"
 role = aws_iam_role.role_example.name
}


# 1.0 Generate the key pair
resource "tls_private_key" "keypair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2.1 Register the public key with AWS
resource "aws_key_pair" "keypair" {
  key_name   = "ce13-kh-keypair"
  public_key = tls_private_key.keypair.public_key_openssh
}

# 2.2 Save the private key locally so you can SSH in
resource "local_file" "private_key" {
  content         = tls_private_key.keypair.private_key_pem
  filename        = "C:/Users/kuoho/Documents/NTU PACE/Module 2/Coaching8/ce13-kh-keypair.pem"
  file_permission = "0600"
}

# 2.3 Generate EC2 Instance
resource "aws_instance" "public" {
  ami                         = "ami-01edba92f9036f76e" # find the AMI ID of Amazon Linux 2023
  instance_type               = "t2.micro"
  iam_instance_profile        = aws_iam_instance_profile.profile_example.name
  subnet_id                   = "subnet-0dca038ba1ab905b2"  #Public Subnet ID, e.g. subnet-xxxxxxxxxxx
  #subnet_id                  = aws_subnet.public.id
  associate_public_ip_address = true
  key_name                    = aws_key_pair.keypair.key_name
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
 
  tags = {
    Name = "ce13-kh-coaching8-ec2"    #Prefix your own name, e.g. jazeel-ec2
  }
}

# 2.1 Generate Security Group for EC2 Instance
resource "aws_security_group" "allow_ssh" {
  name        = "ce13-kh-coaching8-ec2-sg" #Security group name, e.g. jazeel-terraform-security-group
  description = "Allow SSH inbound"
  vpc_id     = "vpc-0eed683a8b9b59570"  #VPC ID (Same VPC as your EC2 subnet above), E.g. vpc-xxxxxxx
  #vpc_id      = aws_vpc.main.id 

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

  egress {
    description = "SQL outbound"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #ingress {
  #  description = "SQL outbound"
  #  from_port   = 3306
  #  to_port     = 3306
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

}

# 2.2 Generate Ingress Rule for Security Group
resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  cidr_ipv4         = "0.0.0.0/0"  
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}


# 3.0 Generate DynamoDB Table
resource "aws_dynamodb_table" "book_inventory" {
  name         = "ce13-kh-coaching8-db-bookinventory"
  billing_mode = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  hash_key  = "ISBN"
  range_key = "Genre"

  attribute {
    name = "ISBN"
    type = "S"
  }

  attribute {
    name = "Genre"
    type = "S"
  }
}


resource "aws_db_subnet_group" "this" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = ["subnet-00dce935a79d89714", "subnet-008d5d151ad502e55"]

  tags = {
    Name = "${local.name_prefix}-db-subnet-group"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage           = 10
  db_name                     = "ce13khcoaching8rdsmydb"
  engine                      = "mysql"
  engine_version              = "8.0"
  instance_class              = "db.t3.micro"
  manage_master_user_password = true
  username                    = "admin"
  parameter_group_name        = "default.mysql8.0"
  db_subnet_group_name        = aws_db_subnet_group.this.name
  #vpc_security_group_ids      = [aws_security_group.rds.id]
  vpc_security_group_ids      = [aws_security_group.allow_ssh.id]
  publicly_accessible         = false
  multi_az                    = false
  skip_final_snapshot         = true
}