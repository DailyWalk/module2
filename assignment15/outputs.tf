output "state_machine_arn" {
  description = "ARN of the Step Functions state machine"
  value       = aws_sfn_state_machine.workflow.arn
}

output "process_lambda_name" {
  description = "Name of the data-processing Lambda function"
  value       = aws_lambda_function.process_data.function_name
}

output "store_lambda_name" {
  description = "Name of the data-storing Lambda function"
  value       = aws_lambda_function.store_data.function_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing processed data"
  value       = aws_dynamodb_table.processed_data.name
}

output "sns_topic_arn" {
  description = "ARN of the SNS topic used for alarm notifications"
  value       = aws_sns_topic.alerts.arn
}

output "cloudwatch_alarm_name" {
  description = "Name of the CloudWatch alarm monitoring items stored"
  value       = aws_cloudwatch_metric_alarm.items_stored.alarm_name
}
