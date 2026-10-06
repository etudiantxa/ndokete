import '../../domain/entities/stock_entity.dart';

class StockMovementModel extends StockMovementEntity {
  const StockMovementModel({
    required super.id,
    required super.itemId,
    required super.type,
    required super.quantity,
    super.reason,
    required super.createdAt,
  });

  factory StockMovementModel.fromJson(Map<String, dynamic> json) =>
      StockMovementModel(
        id: json['id'] as String,
        itemId: json['itemId'] as String,
        type: json['type'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        reason: json['reason'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class StockItemModel extends StockItemEntity {
  const StockItemModel({
    required super.id,
    required super.artisanId,
    required super.name,
    super.category,
    super.description,
    required super.quantity,
    required super.unit,
    super.alertThreshold,
    super.purchasePrice,
    super.imageUrl,
    super.movements,
    required super.createdAt,
    required super.updatedAt,
  });

  factory StockItemModel.fromJson(Map<String, dynamic> json) {
    final rawMovements = json['movements'] as List<dynamic>? ?? [];
    return StockItemModel(
      id: json['id'] as String,
      artisanId: json['artisanId'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      description: json['description'] as String?,
      quantity: (json['quantity'] as num).toDouble(),
      unit: _parseUnit(json['unit'] as String? ?? 'PIECE'),
      alertThreshold: (json['alertThreshold'] as num?)?.toDouble(),
      purchasePrice: (json['purchasePrice'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      movements: rawMovements
          .map((m) => StockMovementModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  static StockUnit _parseUnit(String s) {
    switch (s) {
      case 'METRE': return StockUnit.METRE;
      case 'KG': return StockUnit.KG;
      case 'LITRE': return StockUnit.LITRE;
      default: return StockUnit.PIECE;
    }
  }
}
