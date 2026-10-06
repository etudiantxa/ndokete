import 'package:dartz/dartz.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class UpdateOrderStatusUsecase {
  final OrdersRepository repository;
  UpdateOrderStatusUsecase(this.repository);

  Future<Either<String, OrderEntity>> call(String id, OrderStatus status) =>
      repository.updateOrderStatus(id, status);
}
