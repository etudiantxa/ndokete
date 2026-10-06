import 'package:dartz/dartz.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class CreateOrderUsecase {
  final OrdersRepository repository;
  CreateOrderUsecase(this.repository);

  Future<Either<String, OrderEntity>> call(Map<String, dynamic> data) =>
      repository.createOrder(data);
}
