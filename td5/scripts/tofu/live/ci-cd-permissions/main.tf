provider "aws" {
  region = "eu-north-1"
}

# 1. Module pour créer la liaison de confiance entre GitHub et AWS
module "oidc_provider" {
  source = "github.com/brikis98/devops-book//ch5/tofu/modules/github-aws-oidc"
  provider_url = "https://token.actions.githubusercontent.com"
}

# 2. Module pour créer les rôles IAM Plan et Apply
module "iam_roles" {
  source = "github.com/brikis98/devops-book//ch5/tofu/modules/gh-actions-iam-roles"

  name              = "lambda-sample-lina-v2"
  oidc_provider_arn = module.oidc_provider.oidc_provider_arn

  enable_iam_role_for_testing = true

  # Ton repo GitHub exact
  github_repo      = "LinaOuchaouAmroussi/devops-base"
  
  # Correspond au nom de ta Lambda
  lambda_base_name = "lambda-sample-lina-v2"

  enable_iam_role_for_plan  = true
  enable_iam_role_for_apply = true

  # Tes ressources de State
  tofu_state_bucket         = "tofu-state-lina-amroussi-unique-2026"
  tofu_state_dynamodb_table = "tofu-state-lina-amroussi-unique-2026"
}

# 3. Correction pour l'erreur 403 API Gateway
resource "aws_iam_role_policy" "extra_permissions" {
  name = "extra-permissions-for-apigateway"
  role = "lambda-sample-lina-v2-apply"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "apigateway:*",
          "iam:PassRole",
          "events:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}