import 'package:dartz/dartz.dart';
import '../entities/stock_entity.dart';

abstract class StockRepository {
  Future<Either<String, List<StockItemEntity>>> getStockItems({String? category});
  Future<Either<String, StockItemEntity>> getStockItemById(String id);
  Future<Either<String, StockItemEntity>> createStockItem(Map<String, dynamic> data);
  Future<Either<String, StockItemEntity>> updateStockItem(String id, Map<String, dynamic> data);
  Future<Either<String, void>> deleteStockItem(String id);
  Future<Either<String, StockItemEntity>> adjustStock(String id, double quantity, String type, String? reason);
  Future<Either<String, List<StockItemEntity>>> getLowStockItems();
}
