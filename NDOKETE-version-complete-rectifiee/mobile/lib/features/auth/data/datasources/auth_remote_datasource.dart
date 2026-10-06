import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';

class AuthRemoteDatasource {
  final ApiClient _client;
  final _storage = const FlutterSecureStorage();

  AuthRemoteDatasource(this._client);

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    try {
      final response = await _client.post('/auth/login', data: {
        'identifier': identifier,
        'password': password,
      });
      
      // DEBUG: Afficher la réponse complète dans la console web
      if (kIsWeb) {
        print('=== LOGIN RESPONSE ===');
        print('Status: ${response.statusCode}');
        print('Data: ${response.data}');
        print('=====================');
      }
      
      final data = response.data as Map<String, dynamic>;
      
      // Vérifier la structure de la réponse
      if (data['success'] != true) {
        throw Exception('Réponse API invalide: ${data['message']}');
      }
      
      final responseData = data['data'];
      if (responseData == null || responseData['accessToken'] == null) {
        throw Exception('Tokens manquants dans la réponse');
      }
      
      // Stocker les tokens de manière sécurisée
      await _saveTokens(
        responseData['accessToken'] as String,
        responseData['refreshToken'] as String,
      );
      return (responseData['user'] as Map<String, dynamic>?) ?? {};
    } catch (e) {
      if (kIsWeb) {
        print('=== LOGIN ERROR ===');
        print('Error: $e');
        print('Stack trace: ${StackTrace.current}');
        print('==================');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String password,
    required String role,
    String? businessName,
    String? specialty,
    String? quarter,
  }) async {
    final response = await _client.post('/auth/register', data: {
      'email': email,
      'phone': phone,
      'password': password,
      'role': role,
      if (businessName != null) 'businessName': businessName,
      if (specialty != null) 'specialty': specialty,
      if (quarter != null) 'quarter': quarter,
    });
    final data = response.data as Map<String, dynamic>;
    await _saveTokens(
      data['data']['accessToken'] as String,
      data['data']['refreshToken'] as String,
    );
    return (data['data']['user'] as Map<String, dynamic>?) ?? {};
  }

  Future<Map<String, dynamic>> getMe() async {
    final response = await _client.get('/users/me');
    return (response.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    try {
      await _client.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
  }
}
