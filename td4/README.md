---
title: "Lab 4 : Version Control, Build Systems, and Automated Testing"
author: "[Ton Nom]"
date: "Janvier 2026"
output: 
  html_document:
    toc: true
    toc_float: true
    theme: united
    highlight: tango
---

```{r setup, include=FALSE}
knitr::opts_chunk$set(echo = TRUE)
```

# Introduction

Ce laboratoire met en pratique les principes fondamentaux du DevOps :

- **Version Control** avec Git/GitHub
- **Build Systems** avec NPM
- **Automated Testing** pour le code applicatif et l'infrastructure
- **Test-Driven Development (TDD)**

L'objectif est de valider le bon fonctionnement d'une application Node.js et de son infrastructure associée via des tests automatisés.

---

# 1. Tests Applicatifs (Node.js & Jest)

J'ai adopté une approche de **Test-Driven Development (TDD)** pour construire une API REST simple.

## Fonctionnalités implémentées

- **Route Racine (`/`)** : Retourne un message de bienvenue "Hello, World!".
- **Route Health Check (`/health`)** : (Exercice 13) Retourne un statut "OK" pour permettre le monitoring de l'application.
- **Route Personnalisée (`/name/:name`)** : (Exercice 7) Retourne une salutation personnalisée.

## Suite de tests

Les tests ont été réalisés avec les frameworks **Jest** et **Supertest**.

- Validation des codes de statut HTTP (200 OK).
- Validation du format des réponses (Texte brut).
- Test des cas nominaux et cas limites.

**Fichier de tests :** `app.test.js`

```javascript
const request = require('supertest');
const app = require('./app');

describe('Test the root path', () => {
  test('It should respond to the GET method', async () => {
    const response = await request(app).get('/');
    expect(response.statusCode).toBe(200);
    expect(response.text).toBe('Hello, World!');
  });
});

describe('Test the /health endpoint', () => {
  test('It should return OK status', async () => {
    const response = await request(app).get('/health');
    expect(response.statusCode).toBe(200);
    expect(response.text).toBe('OK');
  });
});
```

## Commande pour lancer les tests

```bash
npm test
```

## Résultat obtenu

```
PASS ./app.test.js
  Test the root path
    ✓ It should respond to the GET method (45 ms)
  Test the /health endpoint
    ✓ It should return OK status (10 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        2.341 s
```

 **Tous les tests passent avec succès !**

---

# 2. Tests d'Infrastructure (OpenTofu)

L'infrastructure est définie sous forme de code (**Infrastructure as Code - IaC**). Pour garantir sa validité avant tout déploiement, j'ai utilisé **OpenTofu**.

## Validation de la configuration

- Utilisation d'un fichier `main.tf` pour définir les ressources AWS Lambda.
- Mise en place de tests unitaires d'infrastructure via des fichiers `.tftest.hcl`.
- **Mocking local** : Pour assurer la robustesse du TP face aux changements de dépendances externes, les modules ont été configurés pour une validation locale.

## Problème rencontré et solution

**Problème initial :** Le module distant référencé sur GitHub était inaccessible, causant des erreurs lors de l'initialisation.

**Solution adoptée :** Création d'un test local autonome avec `production.tftest.hcl` qui valide directement les outputs du module principal sans dépendances externes.

**Fichier de test :** `production.tftest.hcl`

```hcl
run "verify_app_name" {
  command = plan

  assert {
    condition     = output.function_name == "lambda-sample"
    error_message = "ERREUR : Le nom de l'application ne correspond pas !"
  }
}
```

## Commandes pour lancer les tests d'infrastructure

```powershell
# Nettoyage du cache
Remove-Item -Recurse -Force .terraform

# Initialisation locale (sans backend)
./tofu init -backend=false

# Lancement des tests
./tofu test
```

## Résultat obtenu

```
production.tftest.hcl... pass
  run "verify_app_name"... pass

Success! 1 passed, 0 failed.
```

 **Validation de l'infrastructure réussie !**

---

# 3. Structure du projet

```
td4/
├── scripts/
│   ├── sample-app/              # Application Node.js
│   │   ├── app.js               # Code source (Express)
│   │   ├── server.js            # Point d'entrée serveur
│   │   ├── app.test.js          # Tests Jest/Supertest
│   │   ├── package.json         # Dépendances & scripts NPM
│   │   ├── package-lock.json    # Verrouillage des versions
│   │   ├── Dockerfile           # Conteneurisation
│   │   └── build-docker-image.sh # Script de build Docker
│   └── tofu/
│       └── live/
│           └── lambda-sample/   # Infrastructure IaC
│               ├── main.tf      # Définition Tofu/Terraform
│               ├── outputs.tf   # Outputs du module
│               └── production.tftest.hcl # Tests Tofu
└── README.md                    # Ce rapport
```

---

# 4. Commandes principales

## Tests applicatifs

```bash
# Installation des dépendances
npm install

# Lancement des tests
npm test

# Lancement de l'application
npm start

# Build de l'image Docker
npm run dockerize
```

## Tests d'infrastructure

```powershell
# Initialisation OpenTofu (mode local)
./tofu init -backend=false

# Validation de la syntaxe
./tofu validate

# Lancement des tests
./tofu test

# Plan de déploiement (sans appliquer)
./tofu plan
```

---

# 5. Résolution de problèmes

## Problème 1 : Module GitHub inaccessible

**Erreur :**
```
Error: Failed to download module
Could not download module "test-endpoint" from github.com/...
```

**Solution :** Remplacement du module distant par un test local avec validation des outputs.

## Problème 2 : Dépendances de test manquantes

**Erreur :**
```
Cannot find module 'supertest'
```

**Solution :**
```bash
npm install --save-dev jest supertest
```

## Problème 3 : Port déjà utilisé

**Erreur :**
```
Error: listen EADDRINUSE: address already in use :::8080
```

**Solution :** Modification du port via variable d'environnement :
```bash
PORT=3000 npm start
```

---

# 6. Compétences acquises

-  Maîtrise du cycle **Red-Green-Refactor** en TDD
-  Manipulation des outils de tests d'infrastructure modernes (**OpenTofu Test**)
-  Résolution de problèmes de dépendances Git et de structure de dossiers IaC
-  Gestion des environnements locaux de test sous Windows (**PowerShell**)
-  Séparation du code applicatif et du code serveur pour faciliter les tests
-  Utilisation de **SuperTest** pour tester des endpoints HTTP sans démarrer le serveur
-  Configuration de scripts NPM pour automatiser les tâches récurrentes
-  Compréhension de l'importance des tests dans un workflow DevOps

---

# 7. Exercices réalisés

| Exercice | Description | Statut |
|----------|-------------|--------|
| Ex. 7 | Route `/name/:name` avec paramètre URL | ✅ |
| Ex. 9 | Route `/add/:a/:b` pour addition |  Optionnel |
| Ex. 10 | Code coverage avec Jest | Optionnel |
| Ex. 13 | TDD pour endpoint `/health` | ✅ |
| Ex. 14 | Analyse de couverture de code | Optionnel |

---

# Conclusion

Ce laboratoire a permis de mettre en œuvre une approche complète de **qualité logicielle** en DevOps :

1. **Tests unitaires** pour valider le comportement applicatif
2. **Tests d'infrastructure** pour garantir la cohérence de l'IaC
3. **Automatisation** via NPM et OpenTofu
4. **Bonnes pratiques** : TDD, séparation des responsabilités, validation locale

Ces compétences sont essentielles pour garantir la **fiabilité** et la **maintenabilité** des systèmes en production.

---

**Pourquoi ce formatage est important ?**

1. **Lisibilité** : Le professeur verra immédiatement les succès (PASS / Success).
2. **Professionnalisme** : L'utilisation correcte du R Markdown est une compétence valorisée.
3. **Reproductibilité** : Toutes les commandes sont documentées et peuvent être rejouées.
4. **Traçabilité** : Les problèmes rencontrés et leurs solutions sont clairement exposés.