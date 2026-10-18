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
    super.tags,
    super.isVitrine,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    // CORRECTION: Le backend renvoie 'photos', pas 'images' ou 'imageUrls'
    final rawImages = json['photos'] as List<dynamic>? ??
        (json['images'] as List<dynamic>? ?? (json['imageUrls'] as List<dynamic>? ?? []));
    
    // Mapping des tags et isVitrine
    final tags = json['tags'] as List<dynamic>?;
    final isVitrine = json['isVitrine'] as bool? ?? false;
    
    return ProductModel(
      id: json['id'] as String,
      artisanId: json['artisanId'] as String,
      artisanName: artisan?['businessName'] as String? ?? json['artisanName'] as String? ?? '',
      artisanAvatarUrl: artisan?['profilePhoto'] as String?,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String?,
      imageUrls: rawImages.map((e) => e.toString()).toList(),
      status: _parseStatus(json['status'] as String? ?? 'ACTIF'),
      stockQuantity: json['stock'] as int?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewsCount: json['reviewsCount'] as int? ?? 0,
      location: artisan?['quarter'] as String? ?? json['location'] as String?,
      tags: tags?.map((e) => e.toString()).toList(),
      isVitrine: isVitrine,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static ProductStatus _parseStatus(String s) {
    switch (s) {
      case 'INACTIF': return ProductStatus.INACTIF;
      case 'EN_RUPTURE': return ProductStatus.EPUISE;
      default: return ProductStatus.ACTIF;
    }
  }
}
