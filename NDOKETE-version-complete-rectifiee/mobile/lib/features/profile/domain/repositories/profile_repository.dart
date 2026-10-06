import 'package:dartz/dartz.dart';
import '../entities/profile_entity.dart';

abstract class ProfileRepository {
  Future<Either<String, ProfileEntity>> getProfile();
  Future<Either<String, ProfileEntity>> updateProfile(Map<String, dynamic> data);
  Future<Either<String, String>> uploadAvatar(String filePath);
  Future<Either<String, void>> changePassword(String current, String newPassword);
  Future<Either<String, void>> deleteAccount();
}
