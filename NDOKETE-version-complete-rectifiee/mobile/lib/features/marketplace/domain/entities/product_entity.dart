import 'package:equatable/equatable.dart';

enum ProductStatus { ACTIF, INACTIF, EPUISE }

class ProductEntity extends Equatable {
  final String id;
  final String artisanId;
  final String artisanName;
  final String? artisanAvatarUrl;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final List<String> imageUrls;
  final ProductStatus status;
  final int? stockQuantity;
  final double? rating;
  final int reviewsCount;
  final String? location;
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.artisanId,
    required this.artisanName,
    this.artisanAvatarUrl,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrls = const [],
    required this.status,
    this.stockQuantity,
    this.rating,
    this.reviewsCount = 0,
    this.location,
    required this.createdAt,
  });

  bool get isAvailable =>
      status == ProductStatus.ACTIF &&
      (stockQuantity == null || stockQuantity! > 0);

  String get mainImageUrl =>
      imageUrls.isNotEmpty ? imageUrls.first : '';

  @override
  List<Object?> get props => [id, name, price, status];
}

class MarketplaceOrderEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String buyerId;
  final String buyerName;
  final int quantity;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  const MarketplaceOrderEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.buyerId,
    required this.buyerName,
    required this.quantity,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, status];
}
