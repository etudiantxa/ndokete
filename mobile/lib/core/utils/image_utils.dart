import 'package:flutter/foundation.dart';

class ImageUtils {
  static String formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    var formatted = url.trim();

    // 1. Ajouter le préfixe /api/v1/ si absent dans les routes /uploads/
    if (!formatted.contains('/api/v1/') && formatted.contains('/uploads/')) {
      formatted = formatted.replaceAll('/uploads/', '/api/v1/uploads/');
    }

    // 2. Remplacer localhost par 10.0.2.2 sur l'émulateur Android
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && formatted.contains('localhost')) {
      formatted = formatted.replaceAll('localhost', '10.0.2.2');
    }

    return formatted;
  }
}
