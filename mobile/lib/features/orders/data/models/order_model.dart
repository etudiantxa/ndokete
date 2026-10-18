import '../../domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.artisanId,
    required super.customerId,
    required super.customerName,
    super.customerPhone,
    required super.title,
    super.description,
    required super.amount,
    super.amountPaid,
    required super.status,
    super.dueDate,
    super.isUrgent,
    super.notes,
    required super.createdAt,
    required super.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final customer = json['customer'] as Map<String, dynamic>?;
    return OrderModel(
      id: json['id'] as String,
      artisanId: json['artisanId'] as String,
      customerId: json['customerId'] as String? ?? customer?['id'] as String? ?? '',
      customerName: customer?['name'] as String? ?? json['customerName'] as String? ?? '',
      customerPhone: customer?['phone'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      amount: (json['amount'] as num).toDouble(),
      amountPaid: (json['amountPaid'] as num? ?? 0).toDouble(),
      status: _parseStatus(json['status'] as String? ?? 'EN_ATTENTE'),
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isUrgent: json['isUrgent'] as bool? ?? false,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'artisanId': artisanId,
        'customerId': customerId,
        'title': title,
        'description': description,
        'amount': amount,
        'amountPaid': amountPaid,
        'status': status.name,
        'dueDate': dueDate?.toIso8601String(),
        'isUrgent': isUrgent,
        'notes': notes,
      };

  static OrderStatus _parseStatus(String s) {
    switch (s) {
      case 'EN_COURS': return OrderStatus.EN_COURS;
      case 'PRET': return OrderStatus.PRET;
      case 'LIVRE': return OrderStatus.LIVRE;
      case 'ANNULE': return OrderStatus.ANNULE;
      default: return OrderStatus.EN_ATTENTE;
    }
  }
}
