import '../../domain/entities/notification_entity.dart';

class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.userId,
    required super.type,
    required super.title,
    required super.body,
    super.actionUrl,
    super.isRead,
    super.metadata,
    required super.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      NotificationModel(
        id: json['id'] as String,
        userId: json['userId'] as String,
        type: _parseType(json['type'] as String? ?? 'SYSTEM'),
        title: json['title'] as String,
        body: json['body'] as String,
        actionUrl: json['actionUrl'] as String?,
        isRead: json['isRead'] as bool? ?? false,
        metadata: json['metadata'] as Map<String, dynamic>?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static NotificationType _parseType(String s) {
    switch (s) {
      case 'ORDER_REMINDER': return NotificationType.ORDER_REMINDER;
      case 'PAYMENT_RECEIVED': return NotificationType.PAYMENT_RECEIVED;
      case 'STOCK_ALERT': return NotificationType.STOCK_ALERT;
      case 'MARKETPLACE_ORDER': return NotificationType.MARKETPLACE_ORDER;
      default: return NotificationType.SYSTEM;
    }
  }
}

class ReminderConfigModel extends ReminderConfigEntity {
  const ReminderConfigModel({
    required super.id,
    required super.artisanId,
    super.enableDeliveryReminders,
    super.deliveryReminderDaysBefore,
    super.enablePaymentReminders,
    super.enableLowStockAlerts,
    super.preferredChannel,
  });

  factory ReminderConfigModel.fromJson(Map<String, dynamic> json) =>
      ReminderConfigModel(
        id: json['id'] as String,
        artisanId: json['artisanId'] as String,
        enableDeliveryReminders: json['enableDeliveryReminders'] as bool? ?? true,
        deliveryReminderDaysBefore: json['deliveryReminderDaysBefore'] as int? ?? 1,
        enablePaymentReminders: json['enablePaymentReminders'] as bool? ?? true,
        enableLowStockAlerts: json['enableLowStockAlerts'] as bool? ?? true,
        preferredChannel: json['preferredChannel'] as String? ?? 'WHATSAPP',
      );

  Map<String, dynamic> toJson() => {
        'enableDeliveryReminders': enableDeliveryReminders,
        'deliveryReminderDaysBefore': deliveryReminderDaysBefore,
        'enablePaymentReminders': enablePaymentReminders,
        'enableLowStockAlerts': enableLowStockAlerts,
        'preferredChannel': preferredChannel,
      };
}
