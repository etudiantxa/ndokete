import 'package:dartz/dartz.dart';
import '../entities/client_entity.dart';
import '../repositories/clients_repository.dart';

class SaveMeasurementsUsecase {
  final ClientsRepository repository;
  SaveMeasurementsUsecase(this.repository);

  Future<Either<String, MeasurementEntity>> call(
          String clientId, Map<String, dynamic> data) =>
      repository.saveMeasurements(clientId, data);
}
