import 'package:flutter/foundation.dart';

class WolofDictionary {
  static final ValueNotifier<String> currentLanguage = ValueNotifier<String>('fr');

  static const Map<String, String> _frToWolof = {
    // Navigation Bottom Bar
    'Accueil': 'Dalal',
    'Commandes': 'Komand yi',
    'Finance': 'Koom-koom',
    'Profil': 'Profil',
    'Découvrir': 'Gis-gis',
    'Mes Commandes': 'Sama Komand',

    // Dashboard
    'Salam': 'Dalal ak jamm',
    'Actions Rapides': 'Jëf yi gaaw',
    'Ajouter\nCommande': 'Yokkal\nKomand',
    'Nouveau\nClient': 'Yessal\nKiliyan',
    'Dépense': 'Génne xalis',
    'Commandes Récentes': 'Komand yi mujj',
    'Voir tout': 'Gis lépp',
    'Évolution des Ventes': 'Yookute komand yi',
    'Cette semaine': 'Ayubés bi',

    // Statuses
    'En attente': 'Xar nal',
    'En confection': 'Ñu ngi koy ñaw',
    'Prêt': 'Pare na',
    'Livré': 'Yobbu nañu ko',
    'Payé': 'Fay nañu ko',

    // Profile & Menu
    'Langue (Français)': 'Lakk (Wolof 🇸🇳)',
    'Langue (Wolof)': 'Lakk (Wolof 🇸🇳)',
    'Rappels & Notifications Automatiques': 'Yegle yi ak xelal',
    'Synchronisation & Mode Hors-Ligne': 'Denc ak doli xalis offline',
    'Se déconnecter': 'Génne ci kont bi',
  };

  static String tr(String text) {
    if (currentLanguage.value == 'wo') {
      return _frToWolof[text] ?? text;
    }
    return text;
  }

  static void setLanguage(String lang) {
    currentLanguage.value = lang;
  }
}
