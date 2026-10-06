import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.artisanId,
    super.orderId,
    required super.type,
    required super.amount,
    required super.category,
    super.description,
    required super.paymentMethod,
    super.reference,
    super.commissionDeducted,
    super.commissionAmount,
    required super.date,
    required super.createdAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        artisanId: json['artisanId'] as String,
        orderId: json['orderId'] as String?,
        type: json['type'] == 'ENTREE'
            ? TransactionType.ENTREE
            : TransactionType.SORTIE,
        amount: (json['amount'] as num).toDouble(),
        category: json['category'] as String,
        description: json['description'] as String?,
        paymentMethod: _parseMethod(json['paymentMethod'] as String? ?? 'ESPECES'),
        reference: json['reference'] as String?,
        commissionDeducted: json['commissionDeducted'] as bool? ?? false,
        commissionAmount: (json['commissionAmount'] as num?)?.toDouble(),
        date: DateTime.parse(json['date'] as String),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static PaymentMethod _parseMethod(String s) {
    switch (s) {
      case 'WAVE': return PaymentMethod.WAVE;
      case 'ORANGE_MONEY': return PaymentMethod.ORANGE_MONEY;
      case 'CHEQUE': return PaymentMethod.CHEQUE;
      case 'VIREMENT': return PaymentMethod.VIREMENT;
      default: return PaymentMethod.ESPECES;
    }
  }
}

class TreasurySummaryModel extends TreasurySummaryEntity {
  const TreasurySummaryModel({
    required super.totalEntrees,
    required super.totalSorties,
    required super.solde,
    required super.commissionsPaid,
    required super.chartData,
  });

  factory TreasurySummaryModel.fromJson(Map<String, dynamic> json) =>
      TreasurySummaryModel(
        totalEntrees: (json['totalEntrees'] as num).toDouble(),
        totalSorties: (json['totalSorties'] as num).toDouble(),
        solde: (json['solde'] as num).toDouble(),
        commissionsPaid: (json['commissionsPaid'] as num? ?? 0).toDouble(),
        chartData: (json['chartData'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList(),
      );
}
