import 'package:dartz/dartz.dart';
import '../../domain/entities/client_entity.dart';
import '../../domain/repositories/clients_repository.dart';
import '../datasources/clients_remote_datasource.dart';

class ClientsRepositoryImpl implements ClientsRepository {
  final ClientsRemoteDatasource _remote;
  ClientsRepositoryImpl(this._remote);

  @override
  Future<Either<String, List<ClientEntity>>> getClients({String? search}) async {
    try {
      return Right(await _remote.getClients(search: search));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ClientEntity>> getClientById(String id) async {
    try {
      return Right(await _remote.getClientById(id));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ClientEntity>> createClient(Map<String, dynamic> data) async {
    try {
      return Right(await _remote.createClient(data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, ClientEntity>> updateClient(
      String id, Map<String, dynamic> data) async {
    try {
      return Right(await _remote.updateClient(id, data));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, void>> deleteClient(String id) async {
    try {
      await _remote.deleteClient(id);
      return const Right(null);
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, List<MeasurementEntity>>> getMeasurements(
      String clientId) async {
    try {
      return Right(await _remote.getMeasurements(clientId));
    } catch (e) {
      return Left(e.toString());
    }
  }

  @override
  Future<Either<String, MeasurementEntity>> saveMeasurements(
      String clientId, Map<String, dynamic> data) async {
    try {
      return Right(await _remote.saveMeasurements(clientId, data));
    } catch (e) {
      return Left(e.toString());
    }
  }
}
