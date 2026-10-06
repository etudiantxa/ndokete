import 'package:dartz/dartz.dart';
import '../entities/product_entity.dart';

abstract class MarketplaceRepository {
  Future<Either<String, List<ProductEntity>>> getProducts({String? category, String? search});
  Future<Either<String, ProductEntity>> getProductById(String id);
  Future<Either<String, List<ProductEntity>>> getMyProducts();
  Future<Either<String, ProductEntity>> createProduct(Map<String, dynamic> data);
  Future<Either<String, ProductEntity>> updateProduct(String id, Map<String, dynamic> data);
  Future<Either<String, void>> deleteProduct(String id);
  Future<Either<String, MarketplaceOrderEntity>> placeOrder(String productId, int quantity);
  Future<Either<String, List<MarketplaceOrderEntity>>> getMyOrders();
}
