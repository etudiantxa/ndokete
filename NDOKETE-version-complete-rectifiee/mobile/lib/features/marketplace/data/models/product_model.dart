import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.artisanId,
    required super.artisanName,
    super.artisanAvatarUrl,
    required super.name,
    super.description,
    required super.price,
    super.category,
    super.imageUrls,
    required super.status,
    super.stockQuantity,
    super.rating,
    super.reviewsCount,
    super.location,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    final rawImages = json['images'] as List<dynamic>? ??
        (json['imageUrls'] as List<dynamic>? ?? []);
    return ProductModel(
      id: json['id'] as String,
      artisanId: json['artisanId'] as String,
      artisanName: artisan?['name'] as String? ?? json['artisanName'] as String? ?? '',
      artisanAvatarUrl: artisan?['avatarUrl'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String?,
      imageUrls: rawImages.map((e) => e.toString()).toList(),
      status: _parseStatus(json['status'] as String? ?? 'ACTIF'),
      stockQuantity: json['stockQuantity'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static ProductStatus _parseStatus(String s) {
    switch (s) {
      case 'INACTIF': return ProductStatus.INACTIF;
      case 'EPUISE': return ProductStatus.EPUISE;
      default: return ProductStatus.ACTIF;
    }
  }
}
