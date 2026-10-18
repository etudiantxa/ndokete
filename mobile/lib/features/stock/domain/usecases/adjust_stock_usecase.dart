import 'package:dartz/dartz.dart';
import '../entities/stock_entity.dart';
import '../repositories/stock_repository.dart';

class AdjustStockUsecase {
  final StockRepository repository;
  AdjustStockUsecase(this.repository);

  Future<Either<String, StockItemEntity>> call(
          String id, double quantity, String type, String? reason) =>
      repository.adjustStock(id, quantity, type, reason);
}
