########################################
# Package Lambda source code
########################################

data "archive_file" "process_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/process"
  output_path = "${path.module}/build/process.zip"
}

data "archive_file" "store_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda/store"
  output_path = "${path.module}/build/store.zip"
}

########################################
# Lambda #1 - processes incoming data
########################################

resource "aws_lambda_function" "process_data" {
  function_name    = "${var.project_name}-process"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.process_zip.output_path
  source_code_hash = data.archive_file.process_zip.output_base64sha256
  timeout          = 10
}

########################################
# Lambda #2 - stores processed data
########################################

resource "aws_lambda_function" "store_data" {
  function_name    = "${var.project_name}-store"
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  runtime          = "python3.12"
  filename         = data.archive_file.store_zip.output_path
  source_code_hash = data.archive_file.store_zip.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.processed_data.name
    }
  }
}
