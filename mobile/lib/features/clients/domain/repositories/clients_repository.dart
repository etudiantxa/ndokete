import 'package:dartz/dartz.dart';
import '../entities/client_entity.dart';

abstract class ClientsRepository {
  Future<Either<String, List<ClientEntity>>> getClients({String? search});
  Future<Either<String, ClientEntity>> getClientById(String id);
  Future<Either<String, ClientEntity>> createClient(Map<String, dynamic> data);
  Future<Either<String, ClientEntity>> updateClient(String id, Map<String, dynamic> data);
  Future<Either<String, void>> deleteClient(String id);
  Future<Either<String, List<MeasurementEntity>>> getMeasurements(String clientId);
  Future<Either<String, MeasurementEntity>> saveMeasurements(String clientId, Map<String, dynamic> data);
}
