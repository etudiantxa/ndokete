import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../core/storage/hive_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDataSource;
  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<String, UserEntity>> login(String identifier, String password) async {
    try {
      final userData = await remoteDataSource.login(identifier, password);
      final user = _mapToEntity(userData);
      // Stocker l'utilisateur en local pour l'accès offline
      await HiveService.saveItem(HiveService.userBox, 'current_user', userData);
      return Right(user);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left('Erreur de connexion : ${e.toString()}');
    }
  }

  @override
  Future<Either<String, UserEntity>> register({
    required String email,
    required String phone,
    required String password,
    required String role,
    String? businessName,
    String? specialty,
    String? quarter,
  }) async {
    try {
      final userData = await remoteDataSource.register(
        email: email,
        phone: phone,
        password: password,
        role: role,
        businessName: businessName,
        specialty: specialty,
        quarter: quarter,
      );
      final user = _mapToEntity(userData);
      await HiveService.saveItem(HiveService.userBox, 'current_user', userData);
      return Right(user);
    } on DioException catch (e) {
      return Left(_handleDioError(e));
    } catch (e) {
      return Left('Erreur d\'inscription : ${e.toString()}');
    }
  }

  @override
  Future<Either<String, UserEntity>> getCurrentUser() async {
    try {
      // D'abord essayer online
      final userData = await remoteDataSource.getMe();
      await HiveService.saveItem(HiveService.userBox, 'current_user', userData);
      return Right(_mapToEntity(userData));
    } on DioException catch (_) {
      // Fallback offline
      final cached = HiveService.getItem(HiveService.userBox, 'current_user');
      if (cached != null) return Right(_mapToEntity(cached));
      return const Left('Non connecté');
    }
  }

  @override
  Future<void> logout() => remoteDataSource.logout();

  @override
  Future<bool> isLoggedIn() => remoteDataSource.isLoggedIn();

  UserEntity _mapToEntity(Map<String, dynamic> data) {
    final artisan = data['artisan'] as Map<String, dynamic>?;
    return UserEntity(
      id: data['id'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: data['role'] as String? ?? 'CLIENT',
      artisanId: artisan?['id'] as String? ?? data['artisanId'] as String?,
      businessName: artisan?['businessName'] as String?,
      subscriptionPlan: (artisan?['subscription'] as Map?)?['plan'] as String?,
    );
  }

  String _handleDioError(DioException e) {
    if (e.response?.statusCode == 401) {
      return 'Identifiants incorrects (Email ou mot de passe invalide)';
    }
    if (e.response?.statusCode == 409) {
      return 'Email ou téléphone déjà utilisé';
    }
    if (e.response?.statusCode == 403) {
      return 'Accès non autorisé';
    }
    final data = e.response?.data;
    if (data is Map &&
        data['message'] != null &&
        data['message'].toString().isNotEmpty &&
        data['message'].toString() != 'Unauthorized') {
      return data['message'].toString();
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Le serveur prend trop de temps à répondre.';
    }
    return 'Erreur de connexion : ${e.message ?? e.error ?? e.toString()}';
  }
}
