resource "aws_cloudwatch_metric_alarm" "items_stored" {
  alarm_name          = "${var.project_name}-items-stored-alarm"
  alarm_description   = "Fires when at least one item is stored by the StoreData Lambda"
  namespace           = "ServerlessWorkflow"
  metric_name         = "ItemsStored"
  statistic           = "Sum"
  period              = 60    # evaluate over 1-minute windows
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]

  tags = {
    Project = var.project_name
  }
}
