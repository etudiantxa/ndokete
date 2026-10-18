import 'package:equatable/equatable.dart';

enum StockUnit { METRE, PIECE, KG, LITRE }

class StockMovementEntity extends Equatable {
  final String id;
  final String itemId;
  final String type; // ENTREE | SORTIE | AJUSTEMENT
  final double quantity;
  final String? reason;
  final DateTime createdAt;

  const StockMovementEntity({
    required this.id,
    required this.itemId,
    required this.type,
    required this.quantity,
    this.reason,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id];
}

class StockItemEntity extends Equatable {
  final String id;
  final String artisanId;
  final String name;
  final String? category;
  final String? description;
  final double quantity;
  final StockUnit unit;
  final double? alertThreshold;
  final double? purchasePrice;
  final String? imageUrl;
  final List<StockMovementEntity> movements;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StockItemEntity({
    required this.id,
    required this.artisanId,
    required this.name,
    this.category,
    this.description,
    required this.quantity,
    required this.unit,
    this.alertThreshold,
    this.purchasePrice,
    this.imageUrl,
    this.movements = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isLowStock =>
      alertThreshold != null && quantity <= alertThreshold!;

  String get unitLabel {
    switch (unit) {
      case StockUnit.METRE: return 'm';
      case StockUnit.PIECE: return 'pcs';
      case StockUnit.KG: return 'kg';
      case StockUnit.LITRE: return 'L';
    }
  }

  @override
  List<Object?> get props => [id, name, quantity];
}
