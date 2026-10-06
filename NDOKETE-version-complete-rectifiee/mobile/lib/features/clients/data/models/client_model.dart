import '../../domain/entities/client_entity.dart';

class MeasurementModel extends MeasurementEntity {
  const MeasurementModel({
    required super.id,
    required super.clientId,
    required super.type,
    required super.values,
    super.notes,
    required super.createdAt,
  });

  factory MeasurementModel.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'] as Map<String, dynamic>? ?? {};
    return MeasurementModel(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      type: json['type'] as String? ?? 'TAILLEUR',
      values: rawValues.map((k, v) => MapEntry(k, (v as num).toDouble())),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class ClientModel extends ClientEntity {
  const ClientModel({
    required super.id,
    required super.artisanId,
    required super.name,
    super.phone,
    super.email,
    super.address,
    super.avatarUrl,
    super.measurements,
    super.totalOrders,
    super.totalSpent,
    super.lastOrderAt,
    required super.createdAt,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    final rawMeasurements = json['measurements'] as List<dynamic>? ?? [];
    return ClientModel(
      id: json['id'] as String,
      artisanId: json['artisanId'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      address: json['address'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      measurements: rawMeasurements
          .map((m) => MeasurementModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      totalOrders: json['totalOrders'] as int? ?? 0,
      totalSpent: (json['totalSpent'] as num? ?? 0).toDouble(),
      lastOrderAt: json['lastOrderAt'] != null
          ? DateTime.parse(json['lastOrderAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
