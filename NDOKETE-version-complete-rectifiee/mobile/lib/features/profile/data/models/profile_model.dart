import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.artisanType,
    super.shopName,
    super.location,
    super.bio,
    required super.plan,
    super.planExpiresAt,
    super.clientsCount,
    super.clientsLimit,
    super.productsCount,
    super.productsLimit,
    required super.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final artisan = json['artisan'] as Map<String, dynamic>?;
    final sub = json['subscription'] as Map<String, dynamic>?;
    final email = json['email'] as String? ?? '';
    final fallbackName = email.contains('@') ? email.split('@').first : 'Utilisateur';
    final specialties = artisan?['specialty'] as List?;
    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: artisan?['businessName'] as String? ?? fallbackName,
      email: email,
      phone: json['phone'] as String?,
      avatarUrl: artisan?['profilePhoto'] as String?,
      artisanType: _parseType(
          specialties != null && specialties.isNotEmpty
              ? specialties.first.toString()
              : null),
      shopName: artisan?['businessName'] as String?,
      location: artisan?['quarter'] as String?,
      bio: artisan?['description'] as String?,
      plan: _parsePlan(sub?['plan'] as String? ?? json['plan'] as String?),
      planExpiresAt: (sub?['endDate'] ?? sub?['expiresAt']) != null
          ? DateTime.tryParse(
              (sub?['endDate'] ?? sub?['expiresAt']) as String)
          : null,
      clientsCount: artisan?['_count']?['customers'] as int? ?? 0,
      clientsLimit: 20,
      productsCount: artisan?['_count']?['products'] as int? ?? 0,
      productsLimit: 5,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  static ArtisanType? _parseType(String? s) {
    switch (s?.toUpperCase()) {
      case 'TAILLEUR': return ArtisanType.TAILLEUR;
      case 'CORDONNIER': return ArtisanType.CORDONNIER;
      case 'BIJOUTIER': return ArtisanType.BIJOUTIER;
      case 'AUTRE': return ArtisanType.AUTRE;
      default: return null;
    }
  }

  static SubscriptionPlan _parsePlan(String? s) {
    switch (s) {
      case 'PREMIUM': return SubscriptionPlan.PREMIUM;
      case 'PREMIUM_PLUS': return SubscriptionPlan.PREMIUM_PLUS;
      default: return SubscriptionPlan.FREE;
    }
  }
}
