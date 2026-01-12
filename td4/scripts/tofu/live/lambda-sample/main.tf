provider "aws" {
  region = "eu-north-1" # on met ici la region que j avais sur aws
}

# 1. Création du rôle IAM pour la Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_lina"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# 2. Archivage du code (le dossier src doit exister avec un index.js dedans)
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda_function_payload.zip"
}

# 3. La fonction Lambda réelle
resource "aws_lambda_function" "test_lambda" {
  filename      = data.archive_file.lambda.output_path
  function_name = "lambda-sample-lina"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  source_code_hash = data.archive_file.lambda.output_base64sha256
}

# Output pour le test GitHub Actions
output "function_name" {
  value = aws_lambda_function.test_lambda.function_name
}