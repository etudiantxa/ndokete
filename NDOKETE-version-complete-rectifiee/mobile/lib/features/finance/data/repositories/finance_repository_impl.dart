import 'package:dartz/dartz.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/finance_repository.dart';
import '../datasources/finance_remote_datasource.dart';

class FinanceRepositoryImpl implements FinanceRepository {
  final FinanceRemoteDatasource _remote;
  FinanceRepositoryImpl(this._remote);

  @override
  Future<Either<String, TreasurySummaryEntity>> getTreasurySummary({String? period}) async {
    try {
      return Right(await _remote.getTreasurySummary(period: period));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<TransactionEntity>>> getTransactions({
    String? type,
    String? period,
  }) async {
    try {
      return Right(await _remote.getTransactions(type: type, period: period));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, TransactionEntity>> createTransaction(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.createTransaction(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteTransaction(String id) async {
    try {
      await _remote.deleteTransaction(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, Map<String, dynamic>>> generateReport(
      String startDate, String endDate) async {
    try {
      return Right(await _remote.generateReport(startDate, endDate));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
