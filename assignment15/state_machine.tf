resource "aws_sfn_state_machine" "workflow" {
  name     = "${var.project_name}-state-machine"
  role_arn = aws_iam_role.sfn_exec_role.arn

  definition = templatefile("${path.module}/state_machine.asl.json", {
    process_lambda_arn = aws_lambda_function.process_data.arn
    store_lambda_arn   = aws_lambda_function.store_data.arn
  })

  tags = {
    Project = var.project_name
  }
}
