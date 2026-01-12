provider "aws" {
  region = "eu-north-1" 
}

# Module pour créer la liaison de confiance entre GitHub et AWS
module "oidc_provider" {
  source = "github.com/brikis98/devops-book//ch5/tofu/modules/github-aws-oidc"

  provider_url = "https://token.actions.githubusercontent.com" 
}

# Module pour créer les rôles IAM Plan et Apply
module "iam_roles" {
  source = "github.com/brikis98/devops-book//ch5/tofu/modules/gh-actions-iam-roles"

  # On ajoute le v2 pour correspondre à tes ressources créées
  name              = "lambda-sample-lina-v2" 
  oidc_provider_arn = module.oidc_provider.oidc_provider_arn 

  enable_iam_role_for_testing = true 

  # Ton repo GitHub
  github_repo      = "LinaOuchaouAmroussi/devops-base"
  
  # TRÈS IMPORTANT : Doit correspondre au nom de ta Lambda sur AWS
  lambda_base_name = "lambda-sample-lina-v2" 

  enable_iam_role_for_plan  = true 
  enable_iam_role_for_apply = true 

  # Tes ressources de State
  tofu_state_bucket         = "tofu-state-lina-amroussi-unique-2026"
  tofu_state_dynamodb_table = "tofu-state-lina-amroussi-unique-2026"
}