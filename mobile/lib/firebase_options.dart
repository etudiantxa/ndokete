// File generated manually from Firebase console config (project: ndokete)
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        // Ces plateformes utilisent leurs fichiers de config natifs
        // (google-services.json / GoogleService-Info.plist).
        // Si tu obtiens une erreur sur mobile, il faudra générer les
        // vraies options via `flutterfire configure` plus tard,
        // ou récupérer les configs Android/iOS depuis la console Firebase.
        throw UnsupportedError(
          'DefaultFirebaseOptions.currentPlatform: options non générées '
          'pour cette plateforme. Utilise `flutterfire configure` ou '
          'complète ce fichier manuellement avec les valeurs de la console.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBv2JVTNFArMWjz_FXra1XKuKjFNZEZB08',
    appId: '1:942398314608:web:4d0dacbd6013ed9e61fcb5',
    messagingSenderId: '942398314608',
    projectId: 'ndokete',
    authDomain: 'ndokete.firebaseapp.com',
    storageBucket: 'ndokete.firebasestorage.app',
    measurementId: 'G-CQZJ08Z6KK',
  );
}