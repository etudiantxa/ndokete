import 'package:dartz/dartz.dart';
import '../entities/transaction_entity.dart';
import '../repositories/finance_repository.dart';

class GetTreasuryUsecase {
  final FinanceRepository repository;
  GetTreasuryUsecase(this.repository);

  Future<Either<String, TreasurySummaryEntity>> call({String? period}) =>
      repository.getTreasurySummary(period: period);
}
