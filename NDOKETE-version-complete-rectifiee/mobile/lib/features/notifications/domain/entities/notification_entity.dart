import 'package:equatable/equatable.dart';

enum NotificationType {
  ORDER_REMINDER,
  PAYMENT_RECEIVED,
  STOCK_ALERT,
  MARKETPLACE_ORDER,
  SYSTEM,
}

class NotificationEntity extends Equatable {
  final String id;
  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final String? actionUrl;
  final bool isRead;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.actionUrl,
    this.isRead = false,
    this.metadata,
    required this.createdAt,
  });

  NotificationEntity copyWith({bool? isRead}) => NotificationEntity(
        id: id,
        userId: userId,
        type: type,
        title: title,
        body: body,
        actionUrl: actionUrl,
        isRead: isRead ?? this.isRead,
        metadata: metadata,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, isRead];
}

class ReminderConfigEntity extends Equatable {
  final String id;
  final String artisanId;
  final bool enableDeliveryReminders;
  final int deliveryReminderDaysBefore;
  final bool enablePaymentReminders;
  final bool enableLowStockAlerts;
  final String preferredChannel; // SMS | WHATSAPP | PUSH

  const ReminderConfigEntity({
    required this.id,
    required this.artisanId,
    this.enableDeliveryReminders = true,
    this.deliveryReminderDaysBefore = 1,
    this.enablePaymentReminders = true,
    this.enableLowStockAlerts = true,
    this.preferredChannel = 'WHATSAPP',
  });

  @override
  List<Object?> get props => [id, artisanId];
}
