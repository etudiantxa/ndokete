# NDOKETE — Plateforme SaaS + Marketplace pour artisans sénégalais

## Structure du projet

```
ndokete/
├── backend/          # API NestJS (TypeScript)
└── mobile/           # Application Flutter (Dart)
```

---

## Backend NestJS

### Prérequis
- Node.js 20+
- PostgreSQL 16+
- Redis 7+
- Compte Firebase (push notifications)
- Compte Cloudinary (stockage photos)

### Installation
```bash
cd backend
cp .env.example .env
# Remplir les variables dans .env

npm install

# Générer le client Prisma
npm run prisma:generate

# Migrer la base de données
npm run prisma:migrate

# Peupler avec les données de démo
npm run prisma:seed

# Démarrer en développement
npm run start:dev
```

### Avec Docker (recommandé)
```bash
cd backend
docker-compose up -d        # Lance PostgreSQL + Redis
npm run start:dev           # Lance l'API
```

### API Documentation
Une fois démarrée : http://localhost:3000/api/docs

### Modules disponibles
| Module | Routes |
|--------|--------|
| Auth | `POST /api/v1/auth/register`, `login`, `refresh`, `logout` |
| Artisans | `GET /api/v1/artisans/dashboard`, `profile` |
| Commandes | `GET/POST/PATCH /api/v1/artisans/orders` |
| Clients | `GET/POST/PATCH /api/v1/artisans/customers` |
| Stock | `GET/POST/PATCH /api/v1/artisans/stock` |
| Trésorerie | `GET/POST /api/v1/artisans/transactions` |
| Marketplace | `GET /api/v1/marketplace`, `POST /api/v1/marketplace/products` |
| Paiements | `POST /api/v1/payments/initiate` (Wave + Orange Money) |
| Notifications | WebSocket + Push Firebase |
| Sync offline | `POST /api/v1/sync/batch` |
| Analytics | `GET /api/v1/analytics/artisan` |

### Comptes de démo (après seed)
- Artisan : `moussa@ndokete.sn` / `Demo1234!`
- Client : `client@ndokete.sn` / `Demo1234!`

---

## Mobile Flutter

### Prérequis
- Flutter 3.22+ (SDK Dart 3.3+)
- Android Studio / VS Code
- Émulateur Android ou appareil physique

### Installation
```bash
cd mobile

# Installer les dépendances
flutter pub get

# Générer les fichiers de code (freezed, hive, injectable)
dart run build_runner build --delete-conflicting-outputs

# Configurer Firebase
# 1. Créer un projet Firebase
# 2. Ajouter une app Android (package: com.ndokete.app)
# 3. Télécharger google-services.json → android/app/
# 4. Activer Firebase Cloud Messaging

# Lancer sur émulateur/appareil
flutter run
```

### Configuration de l'URL API
Dans `lib/core/network/api_client.dart`, modifier `_baseUrl` :
```dart
// Développement local (émulateur Android)
static const _baseUrl = 'http://10.0.2.2:3000/api/v1';

// Production
static const _baseUrl = 'https://api.ndokete.sn/api/v1';
```

### Écrans implémentés
| Écran | Route Flutter |
|-------|--------------|
| Onboarding (3 étapes) | `/onboarding` |
| Connexion | `/login` |
| Inscription | `/register` |
| Tableau de bord artisan | `/dashboard` |
| Gestion commandes | `/orders` |
| Nouvelle commande | `/orders/new` |
| Détail commande | `/orders/:id` |
| Carnet clients | `/clients` |
| Fiche client | `/clients/:id` |
| Fiche mesures | `/clients/:id/measurements` |
| Inventaire stock | `/stock` |
| Détail matière | `/stock/:id` |
| Trésorerie | `/finance` |
| Nouvelle transaction | `/finance/new` |
| Rapport financier PDF | `/finance/report` |
| Marketplace | `/marketplace` |
| Notifications | `/notifications` |
| Config rappels WhatsApp | `/notifications/config` |

### Architecture Clean Architecture + BLoC
```
lib/
├── core/
│   ├── di/          # Injection de dépendances (get_it)
│   ├── network/     # ApiClient + intercepteur JWT
│   ├── router/      # go_router avec guards auth
│   ├── storage/     # Hive (offline-first)
│   └── theme/       # Palette NDOKETE (or + vert sénégalais)
└── features/
    └── <feature>/
        ├── data/       # DataSources, Repositories
        ├── domain/     # Entities, UseCases, Repository interfaces
        └── presentation/
            ├── bloc/   # BLoC Events/States
            ├── pages/  # Écrans complets
            └── widgets/ # Composants réutilisables
```

---

## Fonctionnalités clés

### Offline-First
- Hive stocke toutes les données localement
- Chaque action offline est mise en queue (`HiveService.addToSyncQueue`)
- Dès reconnexion, `POST /api/v1/sync/batch` synchronise tout
- Le serveur gère les conflits avec résolution automatique

### Paiements
- Wave CI/SN : checkout via URL de paiement
- Orange Money SN : API directe + webhook
- Commission automatique 10% prélevée par NDOKETE
- Tous les paiements vérifiés par webhook signé

### Plan Freemium
| Plan | Prix | Clients | Produits |
|------|------|---------|---------|
| Gratuit | 0 FCFA | 20 max | 5 max |
| Premium | 5 000 FCFA/mois | Illimité | Illimité |
| Premium Plus | 10 000 FCFA/mois | Illimité + Coaching | Illimité |

---

## Prochaines étapes suggérées

1. **Ajouter les assets** — polices Poppins, illustrations onboarding, icônes
2. **Configurer Firebase** — `google-services.json` + FCM channels Android
3. **Intégrer Cloudinary** — upload photos commandes et produits
4. **Tests** — `flutter test` + `npm run test:e2e` (NestJS)
5. **CI/CD** — GitHub Actions → build APK + déploiement API
6. **Wolof i18n** — compléter les fichiers `app_wo.arb`
