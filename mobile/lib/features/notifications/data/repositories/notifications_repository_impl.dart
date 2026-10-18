import 'package:dartz/dartz.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDatasource _remote;
  NotificationsRepositoryImpl(this._remote);

  @override
  Future<Either<String, List<NotificationEntity>>> getNotifications() async {
    try {
      return Right(await _remote.getNotifications());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> markAsRead(String id) async {
    try {
      await _remote.markAsRead(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> markAllAsRead() async {
    try {
      await _remote.markAllAsRead();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteNotification(String id) async {
    try {
      await _remote.deleteNotification(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ReminderConfigEntity>> getReminderConfig() async {
    try {
      return Right(await _remote.getReminderConfig());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ReminderConfigEntity>> updateReminderConfig(
      Map<String, dynamic> data) async {
    try {
      return Right(await _remote.updateReminderConfig(data));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
