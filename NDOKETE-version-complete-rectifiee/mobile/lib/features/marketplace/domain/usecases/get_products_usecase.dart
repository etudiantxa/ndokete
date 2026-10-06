import 'package:dartz/dartz.dart';
import '../entities/product_entity.dart';
import '../repositories/marketplace_repository.dart';

class GetProductsUsecase {
  final MarketplaceRepository repository;
  GetProductsUsecase(this.repository);

  Future<Either<String, List<ProductEntity>>> call({
    String? category,
    String? search,
  }) =>
      repository.getProducts(category: category, search: search);
}
