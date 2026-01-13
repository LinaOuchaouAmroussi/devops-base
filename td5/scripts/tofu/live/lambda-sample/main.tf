provider "aws" {
  region = "eu-north-1"
}

# 1. Rôle IAM pour la Lambda
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_lina_final"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# 2. Archive du code source
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/lambda.zip"
}

# 3. La fonction Lambda
resource "aws_lambda_function" "hello_world" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "lambda-sample-lina-final"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 4. API Gateway (L'entrée HTTP pour accéder à ta Lambda)
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "lambda-api-lina-final"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.lambda_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id           = aws_apigatewayv2_api.lambda_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.hello_world.invoke_arn
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.lambda_api.id
  route_key = "GET /"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# 5. Permission pour que l'API puisse appeler la Lambda
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

# 6. OUTPUTS : C'est ici que l'URL s'affichera
output "api_url" {
  description = "URL à copier dans ton navigateur pour le rapport"
  value       = aws_apigatewayv2_stage.default.invoke_url
}