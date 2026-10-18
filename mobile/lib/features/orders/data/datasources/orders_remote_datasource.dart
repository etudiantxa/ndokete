import '../../../../core/network/api_client.dart';
import '../models/order_model.dart';

class OrdersRemoteDatasource {
  final ApiClient _client;
  OrdersRemoteDatasource(this._client);

  Future<List<OrderModel>> getOrders({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final resp = await _client.get('/artisans/orders$query');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<OrderModel>> getUrgentOrders() async {
    final resp = await _client.get('/artisans/orders/urgent');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<OrderModel> getOrderById(String id) async {
    final resp = await _client.get('/artisans/orders/$id');
    return OrderModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> createOrder(Map<String, dynamic> data) async {
    final resp = await _client.post('/artisans/orders', data: data);
    return OrderModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<OrderModel> updateOrderStatus(String id, String status) async {
    final resp = await _client.patch('/artisans/orders/$id', data: {'status': status});
    return OrderModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteOrder(String id) =>
      _client.delete('/artisans/orders/$id');

  Future<void> sendReminder(String orderId) =>
      _client.post('/artisans/orders/$orderId/reminder');

  Future<void> sendBulkReminders() =>
      _client.post('/artisans/orders/reminders/bulk');
}
