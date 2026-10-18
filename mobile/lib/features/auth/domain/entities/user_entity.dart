import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String phone;
  final String role;
  final String? artisanId;
  final String? businessName;
  final String? profilePhoto;
  final String? subscriptionPlan;

  const UserEntity({
    required this.id,
    required this.email,
    required this.phone,
    required this.role,
    this.artisanId,
    this.businessName,
    this.profilePhoto,
    this.subscriptionPlan,
  });

  bool get isArtisan => role == 'ARTISAN';
  bool get isClient => role == 'CLIENT';
  bool get isAdmin => role == 'ADMIN';
  bool get isPremium =>
      subscriptionPlan == 'PREMIUM' || subscriptionPlan == 'PREMIUM_PLUS';

  @override
  List<Object?> get props => [id, email, phone, role, artisanId];
}
