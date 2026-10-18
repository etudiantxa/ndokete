import 'package:dartz/dartz.dart';
import '../entities/transaction_entity.dart';
import '../repositories/finance_repository.dart';

class CreateTransactionUsecase {
  final FinanceRepository repository;
  CreateTransactionUsecase(this.repository);

  Future<Either<String, TransactionEntity>> call(Map<String, dynamic> data) =>
      repository.createTransaction(data);
}
