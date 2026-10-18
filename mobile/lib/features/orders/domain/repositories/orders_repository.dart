import 'package:dartz/dartz.dart';
import '../entities/order_entity.dart';

abstract class OrdersRepository {
  Future<Either<String, List<OrderEntity>>> getOrders({String? status});
  Future<Either<String, List<OrderEntity>>> getUrgentOrders();
  Future<Either<String, OrderEntity>> getOrderById(String id);
  Future<Either<String, OrderEntity>> createOrder(Map<String, dynamic> data);
  Future<Either<String, OrderEntity>> updateOrderStatus(String id, OrderStatus status);
  Future<Either<String, void>> deleteOrder(String id);
  Future<Either<String, void>> sendReminder(String orderId);
  Future<Either<String, void>> sendBulkReminders();
}
