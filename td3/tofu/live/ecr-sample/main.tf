provider "aws" {
  region = "us-east-2"
}

module "repo" {
  source = "github.com/BTajini/devops-base//td3/tofu/modules/ecr-repo"

  name = "sample-app"
}
