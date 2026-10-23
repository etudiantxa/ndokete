import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSafeStorage {
  final _secureStorage = const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> read({required String key}) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> delete({required String key}) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }
}
