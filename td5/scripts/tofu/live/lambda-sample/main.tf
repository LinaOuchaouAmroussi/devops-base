provider "aws" {
  region = "eu-north-1"
}

# 1. Création du rôle IAM pour la Lambda
# Note: j'ai utilisé "iam_for_lambda" car c'est ce que ton erreur GitHub recherche
resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda_lina_v4" # On change le nom ici pour éviter le conflit "AlreadyExists"

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
  function_name = "lambda-sample-lina-v4" # On change aussi le nom ici
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# 4. API Gateway
resource "aws_apigatewayv2_api" "lambda_api" {
  name          = "lambda-sample-lina-api-v4"
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

# 5. Permission
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_world.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.lambda_api.execution_arn}/*/*"
}

output "api_url" {
  value = aws_apigatewayv2_stage.default.invoke_url
}