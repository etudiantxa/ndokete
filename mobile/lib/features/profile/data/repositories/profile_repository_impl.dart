import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _remote;
  ProfileRepositoryImpl(this._remote);

  String _formatError(Object e) {
    if (e is DioException) {
      final msg = e.response?.data?['message'];
      if (msg != null && msg.toString().isNotEmpty) {
        return msg.toString();
      }
      if (e.response?.statusCode == 401) {
        return 'Session expirée ou mot de passe incorrect. Veuillez vous reconnecter.';
      }
    }
    final str = e.toString();
    if (str.contains('Connection refused') ||
        str.contains('SocketException') ||
        str.contains('connection error') ||
        str.contains('10.0.2.2')) {
      return 'Impossible de contacter le serveur. Vérifiez que le backend est démarré.';
    }
    return str;
  }

  @override
  Future<Either<String, ProfileEntity>> getProfile() async {
    try {
      return Right(await _remote.getProfile());
    } catch (e) {
      return Left(_formatError(e));
    }
  }

  @override
  Future<Either<String, ProfileEntity>> updateProfile(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.updateProfile(data));
    } catch (e) {
      return Left(_formatError(e));
    }
  }

  @override
  Future<Either<String, String>> uploadAvatar(String filePath) async {
    try {
      return Right(await _remote.uploadAvatar(filePath));
    } catch (e) {
      return Left(_formatError(e));
    }
  }

  @override
  Future<Either<String, void>> changePassword(
      String current, String newPassword) async {
    try {
      await _remote.changePassword(current, newPassword);
      return const Right(null);
    } catch (e) {
      return Left(_formatError(e));
    }
  }

  @override
  Future<Either<String, void>> deleteAccount() async {
    try {
      await _remote.deleteAccount();
      return const Right(null);
    } catch (e) {
      return Left(_formatError(e));
    }
  }
}
