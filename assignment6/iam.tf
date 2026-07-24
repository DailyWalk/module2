# 1. IAM Policy - DynamoDB read/list access
resource "aws_iam_policy" "dynamodb_read" {
  name        = "ce13-kh-dynamodb-read"
  description = "Allows List and Read actions on the book inventory DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBListActions"
        Effect = "Allow"
        Action = [
          "dynamodb:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "DynamoDBReadActions"
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:ConditionCheckItem",
          "dynamodb:Describe*",
          "dynamodb:GetItem",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:PartiQLSelect",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.book_inventory.arn,
          "${aws_dynamodb_table.book_inventory.arn}/index/*"
        ]
      }
    ]
  })
}

# 2. IAM Role - trusted by EC2
resource "aws_iam_role" "dynamodb_read_role" {
  name = "ce13-kh-dynamodb-read-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# 3. Attach policy to role
resource "aws_iam_role_policy_attachment" "dynamodb_read_attach" {
  role       = aws_iam_role.dynamodb_read_role.name
  policy_arn = aws_iam_policy.dynamodb_read.arn
}

# 4. Instance profile (wraps the role for EC2 use)
resource "aws_iam_instance_profile" "dynamodb_read_profile" {
  name = "ce13-kh-dynamodb-read-profile"
  role = aws_iam_role.dynamodb_read_role.name
}