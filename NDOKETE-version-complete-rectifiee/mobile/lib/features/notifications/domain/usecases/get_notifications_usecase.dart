import 'package:dartz/dartz.dart';
import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';

class GetNotificationsUsecase {
  final NotificationsRepository repository;
  GetNotificationsUsecase(this.repository);

  Future<Either<String, List<NotificationEntity>>> call() =>
      repository.getNotifications();
}
