import 'package:dartz/dartz.dart';
import '../entities/product_entity.dart';
import '../repositories/marketplace_repository.dart';

class PlaceOrderUsecase {
  final MarketplaceRepository repository;
  PlaceOrderUsecase(this.repository);

  Future<Either<String, MarketplaceOrderEntity>> call(
          String productId, int quantity) =>
      repository.placeOrder(productId, quantity);
}
