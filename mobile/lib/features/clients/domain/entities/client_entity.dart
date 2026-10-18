import 'package:equatable/equatable.dart';

class MeasurementEntity extends Equatable {
  final String id;
  final String clientId;
  final String type; // TAILLEUR, CORDONNIER, BIJOUTIER
  final Map<String, double> values;
  final String? notes;
  final DateTime createdAt;

  const MeasurementEntity({
    required this.id,
    required this.clientId,
    required this.type,
    required this.values,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, clientId, type];
}

class ClientEntity extends Equatable {
  final String id;
  final String artisanId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? avatarUrl;
  final List<MeasurementEntity> measurements;
  final int totalOrders;
  final double totalSpent;
  final DateTime? lastOrderAt;
  final DateTime createdAt;

  const ClientEntity({
    required this.id,
    required this.artisanId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.avatarUrl,
    this.measurements = const [],
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.lastOrderAt,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name, phone];
}
