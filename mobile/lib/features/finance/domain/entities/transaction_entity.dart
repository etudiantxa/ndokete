import 'package:equatable/equatable.dart';

enum TransactionType { ENTREE, SORTIE }
enum PaymentMethod { ESPECES, WAVE, ORANGE_MONEY, CHEQUE, VIREMENT }

class TransactionEntity extends Equatable {
  final String id;
  final String artisanId;
  final String? orderId;
  final TransactionType type;
  final double amount;
  final String category;
  final String? description;
  final PaymentMethod paymentMethod;
  final String? reference;
  final bool commissionDeducted;
  final double? commissionAmount;
  final DateTime date;
  final DateTime createdAt;

  const TransactionEntity({
    required this.id,
    required this.artisanId,
    this.orderId,
    required this.type,
    required this.amount,
    required this.category,
    this.description,
    required this.paymentMethod,
    this.reference,
    this.commissionDeducted = false,
    this.commissionAmount,
    required this.date,
    required this.createdAt,
  });

  double get netAmount => amount - (commissionAmount ?? 0);

  @override
  List<Object?> get props => [id, type, amount, date];
}

class TreasurySummaryEntity extends Equatable {
  final double totalEntrees;
  final double totalSorties;
  final double solde;
  final double commissionsPaid;
  final List<Map<String, dynamic>> chartData;

  const TreasurySummaryEntity({
    required this.totalEntrees,
    required this.totalSorties,
    required this.solde,
    required this.commissionsPaid,
    required this.chartData,
  });

  @override
  List<Object?> get props => [solde, totalEntrees, totalSorties];
}
