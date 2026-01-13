provider "aws" {
  region = "eu-north-1" 
}

# 1. Module pour les rôles GitHub (Chemin local vérifié)
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

# 2. Le fournisseur OIDC (Chemin local vérifié)
module "oidc_provider" {
  source       = "../../modules/github-aws-oidc"
  provider_url = "https://token.actions.githubusercontent.com"
}

# 3. PERMISSIONS SUPPLÉMENTAIRES
# On utilise directement le nom du rôle pour éviter l'erreur "Unsupported attribute"
resource "aws_iam_role_policy" "extra_permissions" {
  name = "extra-permissions-for-apigateway-and-iam"
  
  # Ce nom correspond à la variable "name" du module + le suffixe "-apply"
  role = "lambda-sample-lina-v2-apply"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iam:*",             # Pour autoriser la création du rôle de la Lambda
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