output "api_base_url" {
  description = "Base URL of the deployed HTTP API"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "greet_endpoint" {
  description = "Full URL for the greeting endpoint (append ?name=YourName)"
  value       = "${aws_apigatewayv2_stage.default.invoke_url}/greet"
}

output "lambda_function_name" {
  description = "Name of the deployed Lambda function"
  value       = aws_lambda_function.greeting.function_name
}
