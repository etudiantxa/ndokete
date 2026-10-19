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
    super.role,
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
    final client = json['client'] as Map<String, dynamic>?;
    final sub = (artisan?['subscription'] ?? json['subscription']) as Map<String, dynamic>?;
    final email = json['email'] as String? ?? '';
    final role = json['role'] as String? ?? (artisan != null ? 'ARTISAN' : 'CLIENT');
    final fallbackName = email.contains('@') ? email.split('@').first : 'Utilisateur';
    final specialties = artisan?['specialty'] as List?;

    String profileName = fallbackName;
    if (role == 'ARTISAN' && artisan != null && artisan['businessName'] != null) {
      profileName = artisan['businessName'].toString();
    } else if (client != null && client['name'] != null) {
      profileName = client['name'].toString();
    } else if (json['name'] != null) {
      profileName = json['name'].toString();
    }

    final plan = _parsePlan(sub?['plan'] as String? ?? json['plan'] as String?);
    final isPremium = plan != SubscriptionPlan.FREE;

    return ProfileModel(
      id: json['id'] as String? ?? '',
      name: profileName,
      email: email,
      phone: json['phone'] as String?,
      avatarUrl: artisan?['profilePhoto'] as String?,
      artisanType: _parseType(
          specialties != null && specialties.isNotEmpty
              ? specialties.first.toString()
              : null),
      shopName: artisan?['businessName'] as String?,
      location: role == 'ARTISAN'
          ? (artisan?['quarter'] as String?)
          : (client?['address'] as String?),
      bio: artisan?['description'] as String?,
      role: role,
      plan: plan,
      planExpiresAt: (sub?['endDate'] ?? sub?['expiresAt']) != null
          ? DateTime.tryParse(
              (sub?['endDate'] ?? sub?['expiresAt']) as String)
          : null,
      clientsCount: artisan?['_count']?['customers'] as int? ?? 0,
      clientsLimit: isPremium ? 999999 : 20,
      productsCount: artisan?['_count']?['products'] as int? ?? 0,
      productsLimit: isPremium ? 999999 : 5,
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
