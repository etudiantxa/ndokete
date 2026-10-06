import 'package:dartz/dartz.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remote;
  ProfileRepositoryImpl(this._remote);

  @override
  Future<Either<String, ProfileEntity>> getProfile() async {
    try {
      return Right(await _remote.getProfile());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ProfileEntity>> updateProfile(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.updateProfile(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, String>> uploadAvatar(String filePath) async {
    try {
      return Right(await _remote.uploadAvatar(filePath));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> changePassword(
      String current, String newPassword) async {
    try {
      await _remote.changePassword(current, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
