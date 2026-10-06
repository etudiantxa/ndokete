import 'package:equatable/equatable.dart';

enum OrderStatus { EN_ATTENTE, EN_COURS, PRET, LIVRE, ANNULE }

class OrderEntity extends Equatable {
  final String id;
  final String artisanId;
  final String customerId;
  final String customerName;
  final String? customerPhone;
  final String title;
  final String? description;
  final double amount;
  final double amountPaid;
  final OrderStatus status;
  final DateTime? dueDate;
  final bool isUrgent;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const OrderEntity({
    required this.id,
    required this.artisanId,
    required this.customerId,
    required this.customerName,
    this.customerPhone,
    required this.title,
    this.description,
    required this.amount,
    this.amountPaid = 0,
    required this.status,
    this.dueDate,
    this.isUrgent = false,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  double get amountRemaining => amount - amountPaid;
  bool get isFullyPaid => amountPaid >= amount;

  @override
  List<Object?> get props => [id, status, amount, amountPaid];
}
