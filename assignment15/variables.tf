variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Prefix used for naming all resources"
  type        = string
  default     = "ce13-kh-cloudwatch-alarm-sns-notification"
}

variable "alert_email" {
  description = "Email address to receive SNS notifications when the alarm fires"
  type        = string
}
