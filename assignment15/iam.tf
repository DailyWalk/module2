########################################
# Lambda execution role
########################################

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "${var.project_name}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

# Basic CloudWatch Logs permissions for both Lambdas
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Allow the "store" Lambda to write to DynamoDB
data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect  = "Allow"
    actions = ["dynamodb:PutItem"]
    resources = [aws_dynamodb_table.processed_data.arn]
  }
}

resource "aws_iam_role_policy" "lambda_dynamodb" {
  name   = "${var.project_name}-lambda-dynamodb"
  role   = aws_iam_role.lambda_exec_role.id
  policy = data.aws_iam_policy_document.lambda_dynamodb.json
}

# Allow the "store" Lambda to publish the custom CloudWatch metric
data "aws_iam_policy_document" "lambda_cloudwatch_metrics" {
  statement {
    effect    = "Allow"
    actions   = ["cloudwatch:PutMetricData"]
    resources = ["*"] # PutMetricData does not support resource-level restriction
  }
}

resource "aws_iam_role_policy" "lambda_cloudwatch_metrics" {
  name   = "${var.project_name}-lambda-cloudwatch-metrics"
  role   = aws_iam_role.lambda_exec_role.id
  policy = data.aws_iam_policy_document.lambda_cloudwatch_metrics.json
}

########################################
# Step Functions execution role
########################################

data "aws_iam_policy_document" "sfn_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["states.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "sfn_exec_role" {
  name               = "${var.project_name}-sfn-role"
  assume_role_policy = data.aws_iam_policy_document.sfn_assume_role.json
}

# Allow Step Functions to invoke both Lambda functions
data "aws_iam_policy_document" "sfn_invoke_lambda" {
  statement {
    effect = "Allow"
    actions = ["lambda:InvokeFunction"]
    resources = [
      aws_lambda_function.process_data.arn,
      aws_lambda_function.store_data.arn,
    ]
  }
}

resource "aws_iam_role_policy" "sfn_invoke_lambda" {
  name   = "${var.project_name}-sfn-invoke-lambda"
  role   = aws_iam_role.sfn_exec_role.id
  policy = data.aws_iam_policy_document.sfn_invoke_lambda.json
}
