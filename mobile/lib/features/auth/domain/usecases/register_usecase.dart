import 'package:dartz/dartz.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUsecase {
  final AuthRepository repository;
  RegisterUsecase(this.repository);

  Future<Either<String, UserEntity>> call({
    required String email,
    required String phone,
    required String password,
    required String role,
    String? firstName,
    String? lastName,
    String? address,
    String? businessName,
    String? specialty,
    String? quarter,
  }) {
    return repository.register(
      email: email,
      phone: phone,
      password: password,
      role: role,
      firstName: firstName,
      lastName: lastName,
      address: address,
      businessName: businessName,
      specialty: specialty,
      quarter: quarter,
    );
  }
}
