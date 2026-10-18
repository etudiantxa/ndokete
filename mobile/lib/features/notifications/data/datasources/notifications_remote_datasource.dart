import '../../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDatasource {
  final ApiClient _client;
  NotificationsRemoteDatasource(this._client);

  Future<List<NotificationModel>> getNotifications() async {
    final resp = await _client.get('/notifications');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => NotificationModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> markAsRead(String id) =>
      _client.patch('/notifications/$id/read');

  Future<void> markAllAsRead() =>
      _client.patch('/notifications/read-all');

  Future<void> deleteNotification(String id) =>
      _client.delete('/notifications/$id');

  Future<ReminderConfigModel> getReminderConfig() async {
    final resp = await _client.get('/artisans/reminder-config');
    return ReminderConfigModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ReminderConfigModel> updateReminderConfig(Map<String, dynamic> data) async {
    final resp = await _client.patch('/artisans/reminder-config', data: data);
    return ReminderConfigModel.fromJson(resp.data as Map<String, dynamic>);
  }
}
