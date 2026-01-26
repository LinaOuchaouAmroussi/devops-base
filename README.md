# devops-base
# lab5
[![CI Lab 5](https://github.com/LinaOuchaouAmroussi/devops-base/actions/workflows/main.yml/badge.svg)](https://github.com/LinaOuchaouAmroussi/devops-base/actions/workflows/main.yml)
//////////////
# Rapport Technique : Automatisation du Déploiement Continu (CD)

**Module** : DevOps-Base - TD5  
**Étudiante** : Lina Ouchaou Amroussi  
**Date** : 13 Janvier 2026

---

## Table des Matières

1. [Introduction et Contexte](#introduction)
2. [Partie 1 : Intégration Continue (CI)](#partie-1)
   - 2.1. Tests Automatisés de l'Application
   - 2.2. Configuration OIDC avec AWS
   - 2.3. Tests Automatisés de l'Infrastructure
3. [Partie 2 : Livraison Continue (CD)](#partie-2)
   - 3.1. Choix de la Stratégie de Déploiement
   - 3.2. Configuration du Backend Distant
   - 3.3. Gestion des Rôles IAM et Résolution des Conflits de Permissions
   - 3.4. Workflows GitHub Actions pour le Déploiement
   - 3.5. Tests et Validation de la Pipeline
4. [Analyse des Problèmes Rencontrés](#analyse)
5. [Conclusion](#conclusion)

---

<a name="introduction"></a>

## 1. Introduction et Contexte

Ce travail pratique s'inscrit dans le cadre du module DevOps-Base et vise à mettre en œuvre une chaîne complète d'intégration et de livraison continues (CI/CD) pour une application serverless déployée sur AWS. L'objectif principal était de transformer un processus de déploiement manuel en un système automatisé, sécurisé et auditable, répondant aux standards industriels modernes.

Le projet repose sur une application Lambda simple exposée via API Gateway. Plutôt que de déployer manuellement via des commandes OpenTofu locales, nous avons construit une infrastructure permettant à GitHub Actions de gérer automatiquement le cycle de vie complet de l'application : des tests unitaires jusqu'au déploiement en production, en passant par la planification et la validation des changements d'infrastructure.

Cette approche illustre les principes fondamentaux du DevOps : l'automatisation des processus répétitifs, la réduction des erreurs humaines, la traçabilité via Git, et la sécurité par le moindre privilège.

---

<a name="partie-1"></a>

## 2. Partie 1 : Intégration Continue (CI)

### 2.1. Tests Automatisés de l'Application

La première étape a consisté à mettre en place des tests automatisés pour l'application Node.js. Conformément aux principes de l'intégration continue, chaque modification du code doit être validée par une suite de tests avant d'être intégrée à la branche principale. Nous avons créé un workflow GitHub Actions qui s'exécute automatiquement à chaque push sur le dépôt.

**Extrait du workflow `app-tests.yml`** :

```yaml
name: Sample App Tests
on: push
jobs:
  sample_app_tests:
    name: "Run Tests Using Jest"
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        working-directory: td5/scripts/sample-app
        run: npm install
      - name: Run tests
        working-directory: td5/scripts/sample-app
        run: npm test
```

Ce workflow garantit que toute modification du code applicatif est immédiatement testée. En cas d'échec, le développeur est alerté avant même de créer une Pull Request, ce qui permet de détecter et corriger les régressions au plus tôt dans le cycle de développement.

[ESPACE POUR CAPTURE : Écran GitHub Actions montrant l'exécution réussie du workflow app-tests]

### 2.2. Configuration OIDC avec AWS

Pour permettre à GitHub Actions d'interagir avec AWS de manière sécurisée, nous avons mis en œuvre le protocole OpenID Connect (OIDC). Cette approche élimine le besoin de stocker des clés d'accès AWS permanentes dans les secrets GitHub, remplaçant ces identifiants statiques par des jetons temporaires générés dynamiquement.

La configuration d'OIDC nécessite d'établir une relation de confiance entre AWS et GitHub. Nous avons utilisé le module `github-aws-oidc` pour créer un fournisseur d'identité OIDC dans notre compte AWS, configuré pour accepter uniquement les requêtes provenant de notre dépôt GitHub spécifique.

**Extrait de la configuration OIDC dans `main.tf`** :

```hcl
provider "aws" {
  region = "eu-north-1" 
}

module "oidc_provider" {
  source       = "../../modules/github-aws-oidc"
  provider_url = "https://token.actions.githubusercontent.com"
}
```

L'URL du fournisseur `https://token.actions.githubusercontent.com` est l'endpoint que GitHub utilise pour émettre des jetons JWT (JSON Web Tokens) lors de l'exécution des workflows. AWS vérifie la signature de ces jetons et, si la validation réussit, accorde temporairement les permissions définies dans les rôles IAM associés.

Cette configuration a nécessité une attention particulière lors de l'initialisation. Le paramètre `provider_url` était initialement absent de notre configuration, ce qui empêchait AWS de reconnaître GitHub comme fournisseur d'identité légitime. Une fois ce paramètre ajouté, la relation de confiance a pu être établie correctement.

[ESPACE POUR CAPTURE : Console AWS IAM > Identity Providers montrant le fournisseur GitHub OIDC]

### 2.3. Tests Automatisés de l'Infrastructure

Au-delà des tests applicatifs, nous avons également automatisé les tests d'infrastructure. Ces tests utilisent OpenTofu pour déployer temporairement les ressources AWS, vérifier leur bon fonctionnement, puis les détruire automatiquement. Cette approche garantit que les modifications de code d'infrastructure ne cassent pas l'architecture existante.

Le workflow `infra-tests.yml` s'authentifie auprès d'AWS via OIDC en assumant un rôle IAM dédié aux tests, puis exécute la commande `tofu test` sur le module `lambda-sample`.

**Extrait du workflow `infra-tests.yml`** :

```yaml
jobs:
  opentofu_test:
    name: "Run OpenTofu tests"
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v2
      - uses: aws-actions/configure-aws-credentials@v3
        with:
          role-to-assume: arn:aws:iam::982597090285:role/lambda-sample-lina-v2-tests
          role-session-name: tests-${{ github.run_number }}-${{ github.actor }}
          aws-region: eu-north-1
      - uses: opentofu/setup-opentofu@v1
      - name: Tofu Test
        env:
          TF_VAR_name: lambda-sample-${{ github.run_id }}
        working-directory: td5/scripts/tofu/live/lambda-sample
        run: |
          tofu init -backend=false -input=false
          tofu test -verbose
```

L'utilisation de la variable d'environnement `TF_VAR_name` avec `github.run_id` garantit que chaque exécution de test crée des ressources avec des noms uniques, évitant ainsi les conflits lors d'exécutions parallèles.

[ESPACE POUR CAPTURE : Résultat du workflow infra-tests dans GitHub Actions]

---

<a name="partie-2"></a>

## 3. Partie 2 : Livraison Continue (CD)

### 3.1. Choix de la Stratégie de Déploiement

Conformément aux recommandations du cours, nous avons analysé les différentes stratégies de déploiement disponibles avant de choisir celle la plus adaptée à notre application. Notre application Lambda étant sans état (stateless), nous avons opté pour une stratégie de **déploiement progressif sans remplacement** (Progressive Deployment without Replacement).

Cette approche présente plusieurs avantages pour une architecture serverless :

- **Pas d'interruption de service** : Les requêtes continuent d'être traitées pendant la mise à jour.
- **Rollback simplifié** : En cas de problème, il suffit de redéployer la version précédente.
- **Déploiements fréquents** : La rapidité du processus encourage des livraisons plus fréquentes, réduisant ainsi la taille et le risque de chaque changement.

Nous avons également intégré une stratégie de **promotion** en séparant clairement les phases de planification (Plan) et d'exécution (Apply). Cette séparation permet une revue humaine des changements avant leur application effective, ajoutant une couche de sécurité supplémentaire au processus de déploiement.

### 3.2. Configuration du Backend Distant

La migration vers un backend distant constitue une étape fondamentale pour permettre l'automatisation du déploiement. Le fichier d'état OpenTofu (`.tfstate`) contient l'ensemble des informations sur l'infrastructure déployée. Le stocker localement empêche toute collaboration et rend impossible l'exécution de déploiements depuis des environnements distants comme GitHub Actions.

Nous avons configuré un backend S3 avec verrouillage DynamoDB. Le bucket S3 assure la durabilité et la disponibilité du fichier d'état, tandis que la table DynamoDB gère le système de verrouillage (locking) pour empêcher les modifications concurrentes de l'infrastructure.

**Configuration du module state-bucket** :

```hcl
provider "aws" {
  region = "eu-north-1"
}

module "state" {
  source = "../../modules/state-bucket"
  name   = "tofu-state-lina-amroussi-unique-2026"
}
```

Une fois le bucket et la table créés, nous avons configuré chaque module OpenTofu pour utiliser ce backend distant.

**Extrait de `backend.tf` pour le module lambda-sample** :

```hcl
terraform {
  backend "s3" {
    bucket         = "tofu-state-lina-amroussi-unique-2026"
    key            = "td5/scripts/tofu/live/lambda-sample/terraform.tfstate"
    region         = "eu-north-1"
    encrypt        = true
    dynamodb_table = "tofu-state-lina-amroussi-unique-2026"
  }
}
```

Lors de l'exécution de `tofu init`, OpenTofu a automatiquement détecté l'état local existant et proposé de le migrer vers le nouveau backend S3. Cette migration a permis de centraliser la gestion de l'infrastructure et de préparer le terrain pour les déploiements automatisés via GitHub Actions.

Le paramètre `encrypt = true` garantit que le fichier d'état est chiffré au repos dans S3, protégeant ainsi les données sensibles qu'il pourrait contenir (comme les ARNs de ressources ou certaines configurations).

[ESPACE POUR CAPTURE : Console AWS S3 montrant le bucket avec le fichier .tfstate]

### 3.3. Gestion des Rôles IAM et Résolution des Conflits de Permissions

La configuration des rôles IAM pour GitHub Actions s'est révélée être l'étape la plus complexe du projet. Le module `gh-actions-iam-roles` crée trois rôles distincts, chacun avec des permissions spécifiques :

1. **lambda-sample-lina-v2-tests** : Pour les tests d'infrastructure (création/destruction temporaire de ressources)
2. **lambda-sample-lina-v2-plan** : Pour la planification des changements (lecture seule)
3. **lambda-sample-lina-v2-apply** : Pour l'application des changements (écriture)

**Configuration initiale du module IAM** :

```hcl
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
```

#### Problème 1 : Erreur `AccessDenied` sur `iam:GetRole`

Lors du premier test de la pipeline de Plan, nous avons rencontré l'erreur suivante :

```
Error: reading IAM Role (iam_for_lambda_lina_final): operation error IAM: GetRole, 
https response error StatusCode: 403, RequestID: ..., api error AccessDenied: 
User: arn:aws:sts::982597090285:assumed-role/lambda-sample-lina-v2-plan/... 
is not authorized to perform: iam:GetRole on resource: role iam_for_lambda_lina_final
```

**Analyse de la cause** : Le rôle de Plan, généré par défaut par le module, ne disposait que de permissions minimales. Or, pour comparer l'infrastructure actuelle avec l'infrastructure désirée, OpenTofu doit pouvoir lire les ressources IAM existantes. Sans ces permissions de lecture, impossible de générer un plan cohérent.

**Solution implémentée** : Nous avons ajouté une politique IAM supplémentaire au rôle de Plan pour lui accorder les permissions de lecture nécessaires :

```hcl
resource "aws_iam_role_policy" "plan_extra_permissions" {
  name = "plan-permissions-read-iam"
  role = "lambda-sample-lina-v2-plan"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iam:Get*",
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
```

#### Problème 2 : Permissions insuffisantes pour le rôle Apply

Même après avoir corrigé les permissions du rôle Plan, le workflow Apply échouait avec une erreur similaire lors de la tentative de création du rôle IAM de la Lambda. AWS Lambda nécessite un rôle d'exécution propre, et la création de ce rôle requiert des permissions `iam:*` élevées.

**Solution implémentée** : Nous avons étendu les permissions du rôle Apply pour lui permettre de gérer l'ensemble du cycle de vie de l'infrastructure :

```hcl
resource "aws_iam_role_policy" "extra_permissions" {
  name = "extra-permissions-for-apigateway-and-iam"
  role = "lambda-sample-lina-v2-apply"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "iam:*",             # Nécessaire pour créer le rôle d'exécution Lambda
          "apigateway:*",      # Gestion complète de l'API Gateway
          "lambda:*",          # Gestion complète des fonctions Lambda
          "s3:*",              # Accès au bucket de state
          "dynamodb:*",        # Gestion du lock DynamoDB
          "events:*"           # Gestion des déclencheurs éventuels
        ]
        Resource = "*"
      }
    ]
  })
}
```

**Justification de la portée large** : L'utilisation de `iam:*` peut sembler excessive, mais elle est nécessaire dans le contexte du déploiement serverless. La fonction Lambda nécessite son propre rôle d'exécution, et ce rôle doit être créé, modifié et supprimé au fil des déploiements. Une approche plus restrictive aurait nécessité d'énumérer explicitement chaque action IAM requise, ce qui aurait rendu la configuration fragile et difficile à maintenir.

Pour atténuer le risque de sécurité, nous avons appliqué le principe du moindre privilège au niveau de la relation de confiance (Trust Relationship) du rôle. Le rôle ne peut être assumé que par GitHub Actions, et uniquement depuis notre dépôt spécifique `LinaOuchaouAmroussi/devops-base`.

[ESPACE POUR CAPTURE : Console AWS IAM > Roles > Trust Relationships montrant la restriction au dépôt GitHub]

#### Problème 3 : Erreur `Unsupported attribute`

Lors de la première tentative d'attachement des politiques supplémentaires, nous avons rencontré une erreur de référencement :

```
Error: Unsupported attribute
on main.tf line 31, in resource "aws_iam_role_policy" "extra_permissions":
31:   role = module.iam_roles.aws_iam_role.lambda_deploy_apply[0].name
This object does not have an attribute named "aws_iam_role".
```

**Analyse** : Le module `iam_roles` n'exposait pas ses ressources internes de la manière attendue. Plutôt que d'essayer de corriger le module (ce qui aurait nécessité de modifier du code externe), nous avons contourné le problème en utilisant directement le nom du rôle.

**Solution** : Nous avons remplacé la référence dynamique par le nom du rôle en dur :

```hcl
resource "aws_iam_role_policy" "extra_permissions" {
  name = "extra-permissions-for-apigateway-and-iam"
  role = "lambda-sample-lina-v2-apply"  # Nom explicite du rôle
  # ...
}
```

Cette approche, bien que moins élégante, garantit la fiabilité du déploiement et évite les dépendances complexes entre modules.

### 3.4. Workflows GitHub Actions pour le Déploiement

Nous avons implémenté deux workflows distincts pour gérer le cycle de vie du déploiement : un pour la planification lors des Pull Requests, et un pour l'application après le merge sur la branche main.

#### Workflow de Planification (`tofu-plan.yml`)

Ce workflow se déclenche automatiquement lors de la création ou de la mise à jour d'une Pull Request modifiant les fichiers du module `lambda-sample`. Son rôle est de générer un plan d'exécution OpenTofu et de le publier sous forme de commentaire sur la PR, permettant ainsi une revue humaine avant tout déploiement.

**Extrait du workflow** :

```yaml
name: Tofu Plan
on:
  pull_request:
    branches: ["main"]
    paths: ["td5/scripts/tofu/live/lambda-sample/**"]

jobs:
  plan:
    name: "Tofu Plan"
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v2
      - uses: aws-actions/configure-aws-credentials@v3
        with:
          role-to-assume: arn:aws:iam::982597090285:role/lambda-sample-lina-v2-plan
          role-session-name: plan-${{ github.run_number }}-${{ github.actor }}
          aws-region: eu-north-1
      - uses: opentofu/setup-opentofu@v1
      - name: tofu plan
        id: plan
        working-directory: td5/scripts/tofu/live/lambda-sample
        run: |
          tofu init -no-color -input=false
          tofu plan -no-color -input=false -lock=false
      - uses: peter-evans/create-or-update-comment@v4
        if: always()
        env:
          RESULT_EMOJI: ${{ steps.plan.outcome == 'success' && '✅' || '⚠️' }}
        with:
          issue-number: ${{ github.event.pull_request.number }}
          body: |
            ## ${{ env.RESULT_EMOJI }} `tofu plan` output
            ```${{ steps.plan.outputs.stdout }}```
```

**Points clés de la configuration** :

- **Permissions OIDC** : `id-token: write` est nécessaire pour que GitHub puisse générer un jeton JWT et l'échanger avec AWS.
- **Nom de session unique** : L'utilisation de `github.run_number` et `github.actor` dans le nom de session permet de tracer facilement chaque exécution dans les logs AWS CloudTrail.
- **Option `-lock=false`** : Désactive le verrouillage DynamoDB pour la planification, car cette opération est en lecture seule et ne modifie pas l'infrastructure.
- **Publication conditionnelle** : Le commentaire est publié même en cas d'échec (`if: always()`), permettant aux développeurs de comprendre rapidement ce qui n'a pas fonctionné.

[ESPACE POUR CAPTURE : Commentaire automatique du bot GitHub affichant le plan OpenTofu sur une PR]

#### Workflow d'Application (`tofu-apply.yml`)

Ce workflow se déclenche automatiquement après le merge d'une Pull Request sur la branche main. Il applique réellement les changements d'infrastructure sur AWS et publie le résultat dans un commentaire sur la PR originale (désormais fermée).

**Extrait du workflow** :

```yaml
name: Tofu Apply
on:
  push:
    branches: ["main"]
    paths: ["td5/scripts/tofu/live/lambda-sample/**"]

jobs:
  apply:
    name: "Tofu Apply"
    runs-on: ubuntu-latest
    permissions:
      pull-requests: write
      id-token: write
      contents: read
    steps:
      - name: Checkout repository
        uses: actions/checkout@v2
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v3
        with:
          role-to-assume: arn:aws:iam::982597090285:role/lambda-sample-lina-v2-apply
          role-session-name: apply-${{ github.run_number }}-${{ github.actor }}
          aws-region: eu-north-1
      - name: Setup OpenTofu
        uses: opentofu/setup-opentofu@v1
      - name: Tofu apply
        id: apply
        working-directory: td5/scripts/tofu/live/lambda-sample
        run: |
          tofu init -no-color -input=false
          tofu apply -no-color -input=false -lock-timeout=60m -auto-approve
      - name: Find current PR
        uses: jwalton/gh-find-current-pr@master
        id: find_pr
        with:
          state: all
      - name: Create or update comment
        uses: peter-evans/create-or-update-comment@v4
        if: steps.find_pr.outputs.number
        env:
          RESULT_EMOJI: ${{ steps.apply.outcome == 'success' && '✅' || '⚠️' }}
        with:
          issue-number: ${{ steps.find_pr.outputs.number }}
          body: |
            ## ${{ env.RESULT_EMOJI }} `tofu apply` output
            ```${{ steps.apply.outputs.stdout }}```
```

**Points clés de la configuration** :

- **Flag `-auto-approve`** : Applique automatiquement les changements sans demander de confirmation interactive, ce qui est nécessaire dans un contexte d'automatisation.
- **Timeout de verrouillage** : `-lock-timeout=60m` permet d'attendre jusqu'à 60 minutes si une autre opération détient le verrou DynamoDB.
- **Retrouver la PR originale** : L'action `jwalton/gh-find-current-pr` permet de retrouver la Pull Request qui a déclenché le merge, même si elle est désormais fermée, pour y publier le résultat du déploiement.

[ESPACE POUR CAPTURE : Écran GitHub Actions montrant le workflow Apply réussi]

### 3.5. Tests et Validation de la Pipeline

Pour valider l'ensemble de la chaîne CI/CD, nous avons effectué une modification réelle du code applicatif et observé le comportement complet de la pipeline.

#### Modification du Code

Nous avons modifié le message retourné par la fonction Lambda dans le fichier `src/index.js` :

```javascript
exports.handler = (event, context, callback) => {
  callback(null, {statusCode: 200, body: "Lina's DevOps Tofu Lambda Sample"});
};
```

Nous avons également mis à jour le test d'infrastructure correspondant dans `deploy.tftest.hcl` :

```hcl
assert {
  condition     = data.http.test_endpoint.response_body == "Lina's DevOps Tofu Lambda Sample"
  error_message = "Unexpected body: ${data.http.test_endpoint.response_body}"
}
```

#### Déroulement du Test

1. **Création de la branche** : `git checkout -b test-lina-pipeline`
2. **Commit et push** : Les modifications ont été poussées sur GitHub
3. **Déclenchement automatique** : La Pull Request a déclenché les workflows suivants :
   - `app-tests` : Validation des tests Jest de l'application
   - `infra-tests` : Validation des tests OpenTofu
   - `tofu-plan` : Génération et publication du plan de déploiement
4. **Revue et merge** : Après vérification du plan, la PR a été fusionnée
5. **Déploiement automatique** : Le workflow `tofu-apply` s'est exécuté et a mis à jour la Lambda sur AWS

#### Validation Finale

Une fois le déploiement terminé, l'URL de l'API Gateway a affiché le nouveau message personnalisé, confirmant le succès de l'ensemble de la chaîne de déploiement.

[ESPACE POUR CAPTURE : Navigateur affichant le message modifié via l'URL API Gateway]

---

<a name="analyse"></a>

## 4. Analyse des Problèmes Rencontrés

Au cours de ce projet, nous avons dû résoudre plusieurs problèmes techniques significatifs. Cette section récapitule les principaux blocages et les solutions apportées.

| **Problème** | **Symptôme** | **Cause Racine** | **Solution** |
|--------------|--------------|------------------|--------------|
| **Chemins de modules incorrects** | `Error: Unreadable module directory` lors de `tofu init` | Utilisation de `../../../modules/` alors que la structure réelle nécessitait `../../modules/` | Correction des chemins relatifs dans tous les fichiers `main.tf` pour correspondre à l'arborescence réelle du projet |
| **Permissions IAM insuffisantes (Plan)** | `AccessDenied: not authorized to perform: iam:GetRole` lors de l'exécution du workflow Plan | Le rôle de Plan créé par défaut ne disposait que de permissions minimales, insuffisantes pour lire l'état des ressources IAM | Ajout d'une politique IAM supplémentaire accordant les permissions `iam:Get*` et `iam:List*` au rôle Plan |
| **Permissions IAM insuffisantes (Apply)** | `AccessDenied` lors de la création du rôle d'exécution Lambda | Le déploiement d'une Lambda nécessite la création d'un rôle IAM dédié, ce qui requiert des permissions `iam:*` | Extension des permissions du rôle Apply pour inclure `iam:*`, `apigateway:*`, `lambda:*`, etc. |
| **Erreur de référence de module** | `Error: Unsupported attribute - aws_iam_role` | Le module `iam_roles` n'exposait pas ses ressources internes de la manière attendue | Utilisation du nom du rôle en dur (`lambda-sample-lina-v2-apply`) au lieu d'une référence dynamique |
| **Provider URL manquant** | `Error: Missing required argument - provider_url` lors de `tofu apply` | Le module OIDC nécessite l'URL du fournisseur GitHub pour établir la relation de confiance | Ajout du paramètre `provider_url = "https://token.actions.githubusercontent.com"` dans la configuration du module |

### Leçons Apprises

Cette expérience a mis en évidence plusieurs points importants pour la gestion d'infrastructures complexes :

1. **Le principe du moindre privilège nécessite des ajustements itératifs** : Même avec les meilleures intentions de sécurité, il est difficile de prévoir exactement quelles permissions seront nécessaires. Une approche pragmatique consiste à commencer avec des permissions minimales et à les étendre progressivement en fonction des erreurs rencontrées.

2. **La documentation des modules externes est cruciale** : Les modules réutilisables (comme `gh-actions-iam-roles`) doivent documenter clairement leurs sorties (outputs) et leurs dépendances pour faciliter leur intégration.

3. **Les chemins relatifs sont source d'erreurs** : L'utilisation de chemins relatifs (`../../modules/`) est fragile et sensible à la structure des répertoires. Une alternative serait d'utiliser des sources Git absolues pour les modules, au prix d'une plus grande dépendance à la connectivité réseau.

4. **L'OIDC simplifie considérablement la gestion des identités** : Comparé à la gestion de clés d'accès statiques, OIDC offre une sécurité supérieure et une maintenance réduite, au prix d'une configuration initiale plus complexe.

---

<a name="conclusion"></a>

## 5. Conclusion

Ce travail pratique a permis de mettre en œuvre une chaîne complète de CI/CD pour une application serverless sur AWS, en respectant les meilleures pratiques de l'industrie. Nous avons construit un système où chaque modification du code source est automatiquement testée, planifiée, validée puis déployée, le tout de manière sécurisée et traçable.

### Objectifs Atteints

- ✅ **Backend distant configuré** : Le fichier d'état OpenTofu est stocké sur S3 avec verrouillage DynamoDB
- ✅ **Authentification OIDC** : GitHub Actions s'authentifie auprès d'AWS via des jetons temporaires
- ✅ **Séparation des rôles IAM** : Trois rôles distincts (Tests, Plan, Apply) avec permissions appropriées
- ✅ **Workflows automatisés** : Tests, planification et déploiement entièrement automatisés
- ✅ **Validation fonctionnelle** : L'API Gateway expose correctement la fonction Lambda avec le message personnalisé

### Bénéfices de l'Approche

Cette architecture ap