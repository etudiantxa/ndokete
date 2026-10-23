import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WebSafeStorage {
  static final Map<String, String> _memoryCache = {};
  final _secureStorage = const FlutterSecureStorage();

  Future<void> write({required String key, required String value}) async {
    _memoryCache[key] = value;
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> read({required String key}) async {
    if (_memoryCache.containsKey(key)) return _memoryCache[key];
    try {
      final val = await _secureStorage.read(key: key);
      if (val != null) {
        _memoryCache[key] = val;
        return val;
      }
    } catch (_) {}
    return null;
  }

  Future<void> delete({required String key}) async {
    _memoryCache.remove(key);
    try {
      await _secureStorage.delete(key: key);
    } catch (_) {}
  }

  Future<void> deleteAll() async {
    _memoryCache.clear();
    try {
      await _secureStorage.deleteAll();
    } catch (_) {}
  }
}
