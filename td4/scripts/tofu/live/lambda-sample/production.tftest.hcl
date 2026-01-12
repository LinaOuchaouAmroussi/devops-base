# On définit les variables nécessaires pour le test
variables {
  app_name = "lambda-sample-lina"
}

# Premier test : Vérifier que le plan de création est correct
run "verify_app_name" {
  command = plan

  assert {
    # On compare l'output défini dans main.tf avec le nom attendu
    condition     = output.function_name == "lambda-sample-lina"
    error_message = "ERREUR : Le nom de l'application dans main.tf ne correspond pas au nom attendu (lambda-sample-lina) !"
  }
}

# Deuxième test (Optionnel) : Vérifier que le runtime est bien Node.js 20
run "verify_lambda_runtime" {
  command = plan

  assert {
    condition     = aws_lambda_function.test_lambda.runtime == "nodejs20.x"
    error_message = "ERREUR : Le runtime de la Lambda doit être nodejs20.x !"
  }
}