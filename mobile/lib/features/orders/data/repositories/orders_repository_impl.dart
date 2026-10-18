import 'package:dartz/dartz.dart';
import '../../domain/entities/order_entity.dart';
import '../../domain/repositories/orders_repository.dart';
import '../datasources/orders_remote_datasource.dart';

class OrdersRepositoryImpl implements OrdersRepository {
  final OrdersRemoteDatasource _remote;
  OrdersRepositoryImpl(this._remote);

  @override
  Future<Either<String, List<OrderEntity>>> getOrders({String? status}) async {
    try {
      final orders = await _remote.getOrders(status: status);
      return Right(orders);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<OrderEntity>>> getUrgentOrders() async {
    try {
      return Right(await _remote.getUrgentOrders());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, OrderEntity>> getOrderById(String id) async {
    try {
      return Right(await _remote.getOrderById(id));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, OrderEntity>> createOrder(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.createOrder(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, OrderEntity>> updateOrderStatus(
      String id, OrderStatus status) async {
    try {
      return Right(await _remote.updateOrderStatus(id, status.name));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteOrder(String id) async {
    try {
      await _remote.deleteOrder(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> sendReminder(String orderId) async {
    try {
      await _remote.sendReminder(orderId);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> sendBulkReminders() async {
    try {
      await _remote.sendBulkReminders();
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
