import 'package:dartz/dartz.dart';
import '../entities/order_entity.dart';
import '../repositories/orders_repository.dart';

class GetOrdersUsecase {
  final OrdersRepository repository;
  GetOrdersUsecase(this.repository);

  Future<Either<String, List<OrderEntity>>> call({String? status}) =>
      repository.getOrders(status: status);
}
