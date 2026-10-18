import 'package:dartz/dartz.dart';
import '../entities/transaction_entity.dart';

abstract class FinanceRepository {
  Future<Either<String, TreasurySummaryEntity>> getTreasurySummary({String? period});
  Future<Either<String, List<TransactionEntity>>> getTransactions({String? type, String? period});
  Future<Either<String, TransactionEntity>> createTransaction(Map<String, dynamic> data);
  Future<Either<String, void>> deleteTransaction(String id);
  Future<Either<String, Map<String, dynamic>>> generateReport(String startDate, String endDate);
}
