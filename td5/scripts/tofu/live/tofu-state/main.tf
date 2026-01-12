provider "aws" { 
  region = "eu-north-1" 
} 

module "state" { 
  source = "github.com/LinaOuchaouAmroussi/devops-base//td5/scripts/tofu/modules/state-bucket"
  name   = "tofu-state-lina-amroussi-unique-2026" 
}

# On a enlevé les blocs output d'ici car ils sont déjà dans outputs.tf