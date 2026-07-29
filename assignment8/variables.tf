variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the Elastic Beanstalk application"
  type        = string
  default     = "ce13-kh-eb-sample-nodejs-app"
}

variable "env_name" {
  description = "Name of the Elastic Beanstalk environment"
  type        = string
  default     = "ce13-kh-eb-sample-nodejs-env"
}

variable "solution_stack_name" {
  description = "EB platform/solution stack. Check current options with: aws elasticbeanstalk list-available-solution-stacks"
  type        = string
  #default     = "64bit Amazon Linux 2023 v6.4.4 running Node.js 20"
  default     = "64bit Amazon Linux 2023 v6.6.4 running Node.js 20"
}

variable "instance_type" {
  description = "EC2 instance type for the EB environment"
  type        = string
  default     = "t3.micro"
}

variable "tags" {
  description = "Common tags applied to resources"
  type        = map(string)
  default = {
    Project   = "ce13-kh-eb-terraform"
    ManagedBy = "terraform"
  }
}
