import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../storage/web_safe_storage.dart';

class ApiClient {
  static const String localUrl = 'http://10.0.2.2:4000/api/v1';
  static const String remoteUrl = 'https://api.ndokete.com/api/v1';

  // Par défaut : True en mode Debug (Local Docker), False en mode Release (En ligne Render)
  static final ValueNotifier<bool> useLocalServer = ValueNotifier<bool>(kDebugMode);

  static String get _baseUrl {
    if (useLocalServer.value) {
      if (kIsWeb) return 'http://localhost:4000/api/v1';
      return localUrl;
    }
    return remoteUrl;
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

    useLocalServer.addListener(() {
      dio.options.baseUrl = _baseUrl;
    });

    dio.interceptors.addAll([
      _AuthInterceptor(_secureStorage, dio),
      LogInterceptor(responseBody: true, requestBody: true),
    ]);
  }

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      dio.get(path, queryParameters: params);

  Future<Response> post(String path, {dynamic data}) => dio.post(path, data: data);

  Future<Response> patch(String path, {dynamic data}) => dio.patch(path, data: data);

  Future<Response> delete(String path) => dio.delete(path);
}

class _AuthInterceptor extends Interceptor {
  final WebSafeStorage storage;
  final Dio dio;

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
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.connectionError)) {
      try {
        final retryOptions = err.requestOptions;
        if (retryOptions.baseUrl.contains('localhost')) {
          retryOptions.baseUrl = 'http://10.0.2.2:4000/api/v1';
        } else if (retryOptions.baseUrl.contains('10.0.2.2')) {
          retryOptions.baseUrl = 'https://ndokete.onrender.com/api/v1';
        }
        final response = await dio.fetch(retryOptions);
        return handler.resolve(response);
      } catch (_) {}
    }
    handler.next(err);
  }
}
