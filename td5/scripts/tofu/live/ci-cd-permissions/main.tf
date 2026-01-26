provider "aws" {
  region = "eu-north-1" 
}

# 1. Module pour les rôles GitHub
module "iam_roles" {
  source = "../../modules/gh-actions-iam-roles"

  name                        = "lambda-sample-lina-v2"
  oidc_provider_arn           = module.oidc_provider.oidc_provider_arn
  enable_iam_role_for_testing = true
  enable_iam_role_for_plan    = true
  enable_iam_role_for_apply   = true
  
  github_repo                 = "LinaOuchaouAmroussi/devops-base"
  lambda_base_name            = "lambda-sample-lina-final"
  
  tofu_state_bucket           = "tofu-state-lina-amroussi-unique-2026"
  tofu_state_dynamodb_table   = "tofu-state-lina-amroussi-unique-2026"
}

# 2. Le fournisseur OIDC
module "oidc_provider" {
  source       = "../../modules/github-aws-oidc"
  provider_url = "https://token.actions.githubusercontent.com"
}

# 3. PERMISSIONS POUR LE RÔLE "APPLY" (ÉCRITURE)
resource "aws_iam_role_policy" "extra_permissions" {
  name = "extra-permissions-for-apigateway-and-iam"
  role = "lambda-sample-lina-v2-apply"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iam:*",             # Pour créer/modifier les rôles
          "apigateway:*", 
          "lambda:*", 
          "s3:*", 
          "dynamodb:*", 
          "events:*"
        ]
        Resource = "*"
      }
    ]
  })
}

# 4. PERMISSIONS POUR LE RÔLE "PLAN" (LECTURE) - C'est ce qui corrige ton erreur actuelle
resource "aws_iam_role_policy" "plan_extra_permissions" {
  name = "plan-permissions-read-iam"
  role = "lambda-sample-lina-v2-plan"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iam:Get*",        # Autorise la lecture des rôles IAM existants
          "iam:List*",
          "apigateway:Get*",
          "lambda:Get*",
          "s3:Get*",
          "s3:List*"
        ]
        Resource = "*"
      }
    ]
  })
}