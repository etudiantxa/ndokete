import 'package:dartz/dartz.dart';
import '../entities/client_entity.dart';
import '../repositories/clients_repository.dart';

class GetClientsUsecase {
  final ClientsRepository repository;
  GetClientsUsecase(this.repository);

  Future<Either<String, List<ClientEntity>>> call({String? search}) =>
      repository.getClients(search: search);
}
