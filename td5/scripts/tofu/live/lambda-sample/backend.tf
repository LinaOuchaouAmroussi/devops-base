terraform { 
  backend "s3" { 
    bucket         = "tofu-state-lina-amroussi-unique-2026"
    key            = "td5/scripts/tofu/live/lambda-sample/terraform.tfstate" 
    region         = "eu-north-1" # ou us-east-2 selon ton choix
    encrypt        = true 
    dynamodb_table = "tofu-state-lina-amroussi-unique-2026" 
  } 
}