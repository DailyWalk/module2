output "application_name" {
  description = "Elastic Beanstalk application name"
  value       = aws_elastic_beanstalk_application.app.name
}

output "environment_name" {
  description = "Elastic Beanstalk environment name"
  value       = aws_elastic_beanstalk_environment.env.name
}

output "environment_url" {
  description = "URL of the running application"
  value       = "http://${aws_elastic_beanstalk_environment.env.cname}"
}

output "environment_health" {
  description = "Current health status of the environment"
  value       = aws_elastic_beanstalk_environment.env.tier
}

output "s3_source_bucket" {
  description = "S3 bucket holding the application source bundle"
  value       = aws_s3_bucket.eb_app_bucket.id
}
