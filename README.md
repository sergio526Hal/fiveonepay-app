# FiveOne Pay — Plateforme de paiement en ligne

Application web développée avec **Flutter Web** et **Node.js / Express.js**, intégrant l'API FiveOne Pay pour la gestion des paiements en ligne.

## 1. Présentation du projet

L'objectif de ce projet est de faciliter l'intégration d'un système de paiement en ligne à travers une interface web et un backend sécurisé.

### Fonctionnalités

- Récupération des opérateurs de paiement disponibles.
- Création d'un paiement classique.
- Création de liens de paiement réutilisables.
- Consultation de l'historique et des détails des paiements.
- Suivi du statut des transactions.
- Gestion des plans d'abonnement.
- Routes prévues pour la gestion des clients et des abonnements.
- Consultation du solde FiveOne Pay.
- Réception et vérification des webhooks de paiement.

**Remarque :** certaines fonctionnalités, notamment les abonnements, les webhooks et la consultation du solde, nécessitent encore des tests complémentaires selon la configuration de l'API FiveOne Pay.

## 2. Technologies utilisées

| Technologie | Utilisation |
|---|---|
| Flutter Web | Interface utilisateur |
| Dart | Langage du frontend |
| Node.js | Environnement d'exécution du backend |
| Express.js | Création des routes API |
| FiveOne Pay API | Intégration du service de paiement |
| HTTP / REST | Communication entre le frontend et le backend |
| dotenv | Gestion des variables d'environnement |
| CORS | Autorisation des requêtes entre origines |

## 3. Prérequis

Avant de commencer, installer les outils suivants :

- **Git** : https://git-scm.com/
- **Node.js et npm** : https://nodejs.org/
- **Flutter SDK** : https://docs.flutter.dev/get-started/install
- **Google Chrome** pour exécuter l'application Flutter Web.
- Un compte FiveOne Pay et une clé API adaptée à l'environnement de test.

Vérifier les installations dans le terminal :

```bash
git --version
node --version
npm --version
flutter --version
```

Vérifier également la configuration Flutter :

```bash
flutter doctor
```

## 4. Cloner le projet

Ouvrir un terminal, puis exécuter :

```bash
git clone https://github.com/sergio526Hal/fiveonepay-app.git
```

Entrer dans le dossier du projet :

```bash
cd fiveonepay-app
```

Si le dépôt GitHub porte un autre nom, remplacer `fiveonepay-app` par le nom réel du dépôt.

## 5. Installation du backend

Accéder au dossier backend :

```bash
cd backend
```

Installer les dépendances :

```bash
npm install
```

Si le fichier `package.json` n'existe pas encore, initialiser le projet et installer les packages nécessaires :

```bash
npm init -y
npm install express cors dotenv
```

Revenir au dossier principal :

```bash
cd ..
```

## 6. Configuration des variables d'environnement

Dans le dossier `backend`, créer un fichier nommé `.env`.

Exemple de configuration :

```dotenv
PORT=3000

FIVEONEPAY_SECRET_KEY=YOUR_SECRET_KEY_HERE

FIVEONE_WEBHOOK_SECRET=YOUR_WEBHOOK_SECRET_HERE

FIVEONE_CALLBACK_URL=https://YOUR_PUBLIC_URL/api/webhooks/fiveonepay
```

Remplacer les valeurs d'exemple par les informations fournies par FiveOne Pay.

- `PORT` : port local du backend.
- `FIVEONEPAY_SECRET_KEY` : clé secrète utilisée pour appeler l'API FiveOne Pay.
- `FIVEONE_WEBHOOK_SECRET` : secret utilisé pour vérifier les signatures des webhooks.
- `FIVEONE_CALLBACK_URL` : URL publique du webhook, si nécessaire.

**Sécurité :** ne jamais publier le fichier `.env` ni ses véritables valeurs sur GitHub. Le fichier doit être exclu du suivi Git grâce au `.gitignore`.

En environnement Sandbox, utiliser les clés correspondant à cet environnement.

## 7. Installation du frontend Flutter

Depuis le dossier principal du projet :

```bash
flutter pub get
```

Vérifier que les dépendances sont installées :

```bash
flutter pub deps
```

Si une erreur indique qu'un package Flutter manque, vérifier le fichier `pubspec.yaml` et relancer `flutter pub get`.

## 8. Démarrage du backend

Ouvrir un premier terminal :

```bash
cd backend
node server.js
```

Le serveur doit afficher un message similaire à :

```text
Serveur actif sur http://localhost:3000
Route webhook : /api/webhooks/fiveonepay
```

Laisser ce terminal ouvert pendant l'utilisation de l'application.

### Vérifier le serveur

Ouvrir le navigateur à l'adresse :

http://localhost:3000

Le message attendu est :

```text
FiveOne Pay Backend fonctionne !
```

Pour tester les opérateurs, ouvrir :

http://localhost:3000/api/operators

La réponse dépend de la disponibilité de l'API FiveOne Pay et de la connexion Internet.

## 9. Démarrage de Flutter Web

Ouvrir un **deuxième terminal**, sans arrêter le backend.

Depuis le dossier principal :

```bash
flutter run -d chrome
```

Flutter compile et lance l'application dans Google Chrome.

Si nécessaire, construire une version optimisée pour le déploiement :

```bash
flutter build web --release
```

Les fichiers générés se trouvent dans :

```text
build/web/
```

## 10. Principales routes du backend

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/` | Vérification du backend |
| GET | `/api/operators` | Liste des opérateurs |
| POST | `/api/payments` | Création d'un paiement |
| GET | `/api/payments` | Historique des paiements |
| GET | `/api/payments/:id` | Détails d'un paiement |
| POST | `/api/payment-links` | Création d'un lien de paiement |
| POST | `/api/plans` | Création d'un plan |
| GET | `/api/plans` | Liste des plans |
| GET | `/api/plans/:id` | Détails d'un plan |
| PATCH | `/api/plans/:id` | Modification des champs autorisés |
| POST | `/api/customers` | Création d'un client |
| GET | `/api/customers` | Liste des clients |
| GET | `/api/customers/:id` | Détails d'un client |
| POST | `/api/subscriptions` | Création d'un abonnement |
| GET | `/api/subscriptions` | Liste des abonnements |
| GET | `/api/subscriptions/:id` | Détails d'un abonnement |
| DELETE | `/api/subscriptions/:id` | Demande d'annulation |
| GET | `/api/balance` | Consultation du solde |
| POST | `/api/webhooks/fiveonepay` | Réception des webhooks |

La présence d'une route dans ce tableau ne garantit pas que l'opération correspondante fonctionne dans toutes les configurations. Les routes doivent être testées avec les paramètres et les autorisations requis par la documentation FiveOne Pay.

## 11. Test de création d'un paiement

Utiliser un outil tel que Postman pour envoyer une requête :

**Méthode :** `POST`

**URL :**

```text
http://localhost:3000/api/payments
```

Dans `Body → raw → JSON`, utiliser un exemple adapté à l'environnement Sandbox :

```json
{
  "amount": 10000,
  "reference": "TEST-PAIEMENT-001",
  "operator": "MVOLA",
  "description": "Paiement de test",
  "expiresInMinutes": 15
}
```

Le montant, l'opérateur et les autres paramètres doivent respecter les règles de l'API. Une réponse réussie peut contenir un identifiant de paiement, un statut et un lien de paiement.

Ne pas réutiliser une référence lorsqu'une nouvelle transaction indépendante doit être créée.

## 12. Dépannage

### Le backend ne démarre pas

Vérifier que Node.js est installé, que les dépendances sont disponibles et que le fichier `.env` est correctement configuré.

```bash
cd backend
npm install
node server.js
```

### Impossible de se connecter à `localhost:3000`

Vérifier que le serveur est démarré et qu'aucune autre application n'utilise le port 3000.

### Erreur lors de la création d'un plan

Vérifier les paramètres obligatoires, notamment `name`, `amount`, `interval` et `intervalCount`. La périodicité acceptée par l'API est indiquée dans sa documentation.

### Signature webhook invalide

Vérifier que le secret webhook correspond au compte et à l'environnement FiveOne Pay utilisés, ainsi que le format de signature attendu.

### Le frontend ne communique pas avec le backend

Vérifier l'URL utilisée par Flutter, les règles CORS et l'état du backend.

## 13. Sécurité et limites

- La clé secrète FiveOne Pay doit rester dans le backend.
- Le fichier `.env` ne doit pas être publié sur GitHub.
- Les tests de paiement doivent commencer dans l'environnement Sandbox.
- Les données conservées uniquement en mémoire, comme certains statuts de webhook, sont perdues au redémarrage du serveur.
- Pour la production, utiliser une base de données, une gestion robuste des erreurs, des logs adaptés et des contrôles de sécurité supplémentaires.
- L'application doit utiliser une URL HTTPS lorsque le backend est déployé publiquement.

## 14. Auteur

**MAMINOMENA Halinirina Sergio**

GitHub : https://github.com/sergio526Hal

---

*Projet en cours de développement et de validation des fonctionnalités FiveOne Pay.*
