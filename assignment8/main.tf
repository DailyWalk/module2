terraform {
  required_version = ">= 1.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

# ---------------------------------------------------------------------------
# Dynamically look up the current Node.js solution stack instead of
# hardcoding a version, since AWS periodically retires old stack names.
# ---------------------------------------------------------------------------
data "aws_elastic_beanstalk_solution_stack" "nodejs" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux 2023 .* running Node\\.js 20$"
}

# ---------------------------------------------------------------------------
# Package the sample app into a zip that Elastic Beanstalk can deploy
# ---------------------------------------------------------------------------
data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/app"
  output_path = "${path.module}/build/app.zip"
}

# ---------------------------------------------------------------------------
# Minimal VPC for the EB environment (some accounts have no default VPC)
# ---------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "eb_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = "${var.app_name}-vpc" })
}

resource "aws_internet_gateway" "eb_igw" {
  vpc_id = aws_vpc.eb_vpc.id
  tags   = merge(var.tags, { Name = "${var.app_name}-igw" })
}

resource "aws_subnet" "eb_public_subnet" {
  vpc_id                  = aws_vpc.eb_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(var.tags, { Name = "${var.app_name}-public-subnet" })
}

resource "aws_route_table" "eb_public_rt" {
  vpc_id = aws_vpc.eb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eb_igw.id
  }

  tags = merge(var.tags, { Name = "${var.app_name}-public-rt" })
}

resource "aws_route_table_association" "eb_public_rt_assoc" {
  subnet_id      = aws_subnet.eb_public_subnet.id
  route_table_id = aws_route_table.eb_public_rt.id
}

# ---------------------------------------------------------------------------
# S3 bucket to store the application source bundle
# ---------------------------------------------------------------------------
resource "aws_s3_bucket" "eb_app_bucket" {
  bucket = "${var.app_name}-${data.aws_caller_identity.current.account_id}-src"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "eb_app_bucket_versioning" {
  bucket = aws_s3_bucket.eb_app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "app_zip_object" {
  bucket = aws_s3_bucket.eb_app_bucket.id
  key    = "app-${data.archive_file.app_zip.output_md5}.zip"
  source = data.archive_file.app_zip.output_path
  etag   = data.archive_file.app_zip.output_md5
}

# ---------------------------------------------------------------------------
# IAM: instance profile role that EC2 instances in the EB environment assume
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eb_ec2_role" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_multicontainer_docker" {
  role       = aws_iam_role.eb_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkMulticontainerDocker"
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.eb_ec2_role.name
}

# ---------------------------------------------------------------------------
# IAM: service role that Elastic Beanstalk itself assumes
# ---------------------------------------------------------------------------
resource "aws_iam_role" "eb_service_role" {
  name = "${var.app_name}-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "elasticbeanstalk.amazonaws.com" }
      Condition = {
        StringEquals = { "sts:ExternalId" = "elasticbeanstalk" }
      }
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "eb_service_enhanced_health" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSElasticBeanstalkEnhancedHealth"
}

resource "aws_iam_role_policy_attachment" "eb_service_managed_updates" {
  role       = aws_iam_role.eb_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkManagedUpdatesCustomerRolePolicy"
}

# ---------------------------------------------------------------------------
# Elastic Beanstalk application + version + environment
# ---------------------------------------------------------------------------
resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app_name
  description = "Sample Node.js Hello World app deployed via Terraform"
  tags        = var.tags
}

resource "aws_elastic_beanstalk_application_version" "app_version" {
  name        = "v-${data.archive_file.app_zip.output_md5}"
  application = aws_elastic_beanstalk_application.app.name
  bucket      = aws_s3_bucket.eb_app_bucket.id
  key         = aws_s3_object.app_zip_object.key
  tags        = var.tags
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = var.env_name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.nodejs.name
  version_label       = aws_elastic_beanstalk_application_version.app_version.name
  tags                = var.tags

  # Single-instance environment (no load balancer) -> cheapest option for a demo
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "SingleInstance"
  }

  # VPC placement (required when the account has no default VPC)
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.eb_vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.eb_public_subnet.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "true"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "development"
  }
}
