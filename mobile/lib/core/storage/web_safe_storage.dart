import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class WebSafeStorage {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      if (kIsWeb) {
        try {
          html.window.localStorage[key] = value;
        } catch (_) {}
      }
    }
  }

  Future<String?> read({required String key}) async {
    try {
      final val = await _secureStorage.read(key: key);
      if (val != null) return val;
    } catch (_) {}
    if (kIsWeb) {
      try {
        return html.window.localStorage[key];
      } catch (_) {}
    }
    return null;
  }

  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
    if (kIsWeb) {
      try {
        html.window.localStorage.remove(key);
      } catch (_) {}
    }
  }

  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
    if (kIsWeb) {
      try {
        html.window.localStorage.remove('access_token');
        html.window.localStorage.remove('refresh_token');
      } catch (_) {}
    }
  }
}
