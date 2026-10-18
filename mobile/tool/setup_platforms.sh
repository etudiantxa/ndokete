#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter SDK est requis pour générer Android, iOS et Web." >&2
  exit 1
fi

flutter create --platforms=android,ios,web .
flutter pub get
dart run build_runner build --delete-conflicting-outputs

cat <<'EOF'

Plateformes générées.

Démarrage Web :
  flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api/v1

Démarrage Android Emulator :
  flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:3000/api/v1

Démarrage iOS Simulator :
  flutter run -d ios --dart-define=API_BASE_URL=http://localhost:3000/api/v1

Pour un téléphone réel, remplacez API_BASE_URL par l’adresse IP locale
de l’ordinateur qui exécute le backend.
EOF