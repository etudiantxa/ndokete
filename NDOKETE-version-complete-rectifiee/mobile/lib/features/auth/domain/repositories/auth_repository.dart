import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<Either<String, UserEntity>> login(String identifier, String password);
  Future<Either<String, UserEntity>> register({
    required String email,
    required String phone,
    required String password,
    required String role,
    String? businessName,
    String? specialty,
    String? quarter,
  });
  Future<Either<String, UserEntity>> getCurrentUser();
  Future<void> logout();
  Future<bool> isLoggedIn();
}
