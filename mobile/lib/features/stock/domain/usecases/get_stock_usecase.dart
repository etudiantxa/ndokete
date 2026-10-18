import 'package:dartz/dartz.dart';
import '../entities/stock_entity.dart';
import '../repositories/stock_repository.dart';

class GetStockUsecase {
  final StockRepository repository;
  GetStockUsecase(this.repository);

  Future<Either<String, List<StockItemEntity>>> call({String? category}) =>
      repository.getStockItems(category: category);
}
