import 'package:equatable/equatable.dart';

enum ArtisanType { TAILLEUR, CORDONNIER, BIJOUTIER, AUTRE }
enum SubscriptionPlan { FREE, PREMIUM, PREMIUM_PLUS }

class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final ArtisanType? artisanType;
  final String? shopName;
  final String? location;
  final String? bio;
  final SubscriptionPlan plan;
  final DateTime? planExpiresAt;
  final int clientsCount;
  final int clientsLimit;
  final int productsCount;
  final int productsLimit;
  final DateTime createdAt;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.artisanType,
    this.shopName,
    this.location,
    this.bio,
    required this.plan,
    this.planExpiresAt,
    this.clientsCount = 0,
    this.clientsLimit = 20,
    this.productsCount = 0,
    this.productsLimit = 5,
    required this.createdAt,
  });

  bool get isPremium => plan != SubscriptionPlan.FREE;

  double get clientsUsagePercent =>
      clientsLimit > 0 ? (clientsCount / clientsLimit).clamp(0, 1) : 0;

  double get productsUsagePercent =>
      productsLimit > 0 ? (productsCount / productsLimit).clamp(0, 1) : 0;

  String get planLabel {
    switch (plan) {
      case SubscriptionPlan.FREE: return 'Gratuit';
      case SubscriptionPlan.PREMIUM: return 'Premium — 5 000 FCFA/mois';
      case SubscriptionPlan.PREMIUM_PLUS: return 'Premium+ — 10 000 FCFA/mois';
    }
  }

  @override
  List<Object?> get props => [id, plan, clientsCount, productsCount];
}
