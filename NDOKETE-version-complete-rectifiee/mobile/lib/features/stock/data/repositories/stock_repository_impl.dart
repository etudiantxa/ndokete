import 'package:dartz/dartz.dart';
import '../../domain/entities/stock_entity.dart';
import '../../domain/repositories/stock_repository.dart';
import '../datasources/stock_remote_datasource.dart';

class StockRepositoryImpl implements StockRepository {
  final StockRemoteDatasource _remote;
  StockRepositoryImpl(this._remote);

  @override
  Future<Either<String, List<StockItemEntity>>> getStockItems({String? category}) async {
    try {
      return Right(await _remote.getStockItems(category: category));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, StockItemEntity>> getStockItemById(String id) async {
    try {
      return Right(await _remote.getStockItemById(id));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, StockItemEntity>> createStockItem(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.createStockItem(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, StockItemEntity>> updateStockItem(
      String id, Map<String, dynamic> data) async {
    try {
      return Right(await _remote.updateStockItem(id, data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteStockItem(String id) async {
    try {
      await _remote.deleteStockItem(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, StockItemEntity>> adjustStock(
      String id, double quantity, String type, String? reason) async {
    try {
      return Right(await _remote.adjustStock(id, quantity, type, reason));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<StockItemEntity>>> getLowStockItems() async {
    try {
      return Right(await _remote.getLowStockItems());
    } catch (e) {
      return Left(e.toString());
    }
  }
}
