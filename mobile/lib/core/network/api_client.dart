import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/web_safe_storage.dart';

class ApiClient {
  static const _prodUrl = 'https://api.ndokete.sn/api/v1';
  static const _configuredUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: '');

  static String get _baseUrl {
    if (_configuredUrl.isNotEmpty) return _configuredUrl;
    if (kIsWeb) return 'http://localhost:4000/api/v1';
    // Pour un vrai téléphone portable branché en USB, on pointe vers l'IP Wi-Fi du PC (192.168.1.13)
    if (!kDebugMode) return 'http://192.168.1.13:4000/api/v1';
    return 'http://10.0.2.2:4000/api/v1';
  }

  late final Dio dio;
  final _secureStorage = WebSafeStorage();

  ApiClient() {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      persistentConnection: false,
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
    ));

    dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage, dio),
      LogInterceptor(responseBody: true, requestBody: true), // Toujours activé pour débogage web
    ]);
  }

  // Raccourcis pour les appels API
  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) => dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) => dio.patch(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);
}

/// Intercepteur JWT : injecte le token et gère le refresh automatique
class _AuthInterceptor extends Interceptor {
  final WebSafeStorage storage;
  final Dio dio;
  bool _isRefreshing = false;

  _AuthInterceptor(this.storage, this.dio);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await storage.read(key: 'access_token');
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    // Bascule automatique de secours de localhost vers 10.0.2.2 ou IP Wi-Fi PC (192.168.1.13) sur Android
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.connectionError)) {
      try {
        final retryOptions = err.requestOptions;
        if (retryOptions.baseUrl.contains('localhost')) {
          retryOptions.baseUrl = 'http://10.0.2.2:4000/api/v1';
        } else if (retryOptions.baseUrl.contains('10.0.2.2')) {
          retryOptions.baseUrl = 'http://192.168.1.13:4000/api/v1';
        }
        final response = await dio.fetch(retryOptions);
        return handler.resolve(response);
      } catch (_) {}
    }

    final path = err.requestOptions.path;
    final isAuthEndpoint = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/users/me/password');

    if (err.response?.statusCode == 401 && !_isRefreshing && !isAuthEndpoint) {
      _isRefreshing = true;
      try {
        final refreshToken = await storage.read(key: 'refresh_token');
        if (refreshToken == null) {
          await _clearTokens();
          return handler.next(err);
        }

        // Appel refresh
        final response = await dio.post(
          '/auth/refresh',
          data: {'refreshToken': refreshToken},
          options: Options(headers: {'Authorization': ''}), // Éviter boucle
        );

        final newAccessToken = response.data['data']['accessToken'];
        final newRefreshToken = response.data['data']['refreshToken'];

        await storage.write(key: 'access_token', value: newAccessToken);
        await storage.write(key: 'refresh_token', value: newRefreshToken);

        // Rejouer la requête originale avec le nouveau token
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await dio.fetch(err.requestOptions);
        return handler.resolve(retryResponse);
      } catch (_) {
        await _clearTokens();
        handler.next(err);
      } finally {
        _isRefreshing = false;
      }
    } else {
      handler.next(err);
    }
  }

  Future<void> _clearTokens() async {
    await storage.deleteAll();
  }
}
