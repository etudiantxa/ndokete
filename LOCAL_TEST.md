# Tester NDOKETE en local

## 1. Préparer le backend

Prérequis : Node.js 20+, PostgreSQL 16+, Redis 7+ et Flutter 3.22+ pour l’application mobile.

```bash
cd backend
cp .env.example .env
```

Dans `.env`, renseigner au minimum une base PostgreSQL locale et deux secrets JWT suffisamment longs.

Avec Docker, PostgreSQL et Redis peuvent être démarrés ainsi :

```bash
docker compose up -d
```

Puis initialiser et démarrer l’API :

```bash
npm install
npm run prisma:generate
npm run prisma:migrate
npm run prisma:seed
npm run start:dev
```

L’API est disponible sur `http://localhost:3000/api/v1` et sa documentation sur
`http://localhost:3000/api/docs`.

Comptes de démonstration après le seed :

- Artisan : `moussa@ndokete.sn` / `Demo1234!`
- Client : `client@ndokete.sn` / `Demo1234!`

Les appels Wave, Orange Money, Firebase et Cloudinary nécessitent leurs
identifiants respectifs. Les parcours de connexion, atelier et marketplace
peuvent être testés avec les données de démonstration sans activer ces services.

## 2. Préparer l’application Flutter

Dans un autre terminal :

```bash
cd mobile
bash tool/setup_platforms.sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Le script génère les dossiers `android/`, `ios/` et `web/` avec le SDK Flutter
installé sur votre ordinateur. Le dossier `web/` de base est déjà inclus dans
le projet.

L’URL API peut être passée sans modifier le code :

```bash
# Web
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1

# Android Emulator
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

# iOS Simulator
flutter run -d ios --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

Pour un téléphone réel, remplacez l’URL par l’adresse IP locale de l’ordinateur,
par exemple `http://192.168.1.20:3000/api/v1`.

Firebase doit être configuré dans le projet mobile avant le démarrage complet de
l’application (`google-services.json` pour Android et configuration Firebase
correspondante pour iOS).

## 3. Vérifications rapides

Backend :

```bash
cd backend
npm run build
npx prisma validate
```

Mobile :

```bash
cd mobile
flutter analyze
flutter test
```
