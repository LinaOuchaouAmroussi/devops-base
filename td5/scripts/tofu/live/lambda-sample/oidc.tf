# Ce bloc crée le rôle que GitHub va utiliser via son ARN
resource "aws_iam_role" "github_oidc_role" {
  name = "github-oidc-role-lina"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub": "repo:LinaOuchaouAmroussi/devops-base:*"
          },
          "StringEquals": {
            "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# On donne les droits au rôle pour qu'il puisse déployer la Lambda
resource "aws_iam_role_policy_attachment" "admin_access" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_caller_identity" "current" {}

output "role_arn_to_copy" {
  value = aws_iam_role.github_oidc_role.arn
}