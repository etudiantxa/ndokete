import 'package:dartz/dartz.dart';
import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/marketplace_repository.dart';
import '../datasources/marketplace_remote_datasource.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDatasource _remote;
  MarketplaceRepositoryImpl(this._remote);

  @override
  Future<Either<String, List<ProductEntity>>> getProducts({
    String? category,
    String? search,
  }) async {
    try {
      return Right(await _remote.getProducts(category: category, search: search));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ProductEntity>> getProductById(String id) async {
    try {
      return Right(await _remote.getProductById(id));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<ProductEntity>>> getMyProducts() async {
    try {
      return Right(await _remote.getMyProducts());
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ProductEntity>> createProduct(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.createProduct(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ProductEntity>> updateProduct(
      String id, Map<String, dynamic> data) async {
    try {
      return Right(await _remote.updateProduct(id, data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteProduct(String id) async {
    try {
      await _remote.deleteProduct(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, MarketplaceOrderEntity>> placeOrder(
      String productId, int quantity) async {
    try {
      await _remote.placeOrder(productId, quantity);
      return Right(MarketplaceOrderEntity(
        id: '',
        productId: productId,
        productName: '',
        buyerId: '',
        buyerName: '',
        quantity: quantity,
        totalAmount: 0,
        status: 'EN_ATTENTE',
        createdAt: DateTime.now(),
      ));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<MarketplaceOrderEntity>>> getMyOrders() async {
    try {
      return const Right([]);
    } catch (e) {
      return Left(e.toString());
    }
  }
}
