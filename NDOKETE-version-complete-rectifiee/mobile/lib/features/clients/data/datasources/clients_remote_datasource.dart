import '../../../../core/network/api_client.dart';
import '../models/client_model.dart';

class ClientsRemoteDatasource {
  final ApiClient _client;
  ClientsRemoteDatasource(this._client);

  Future<List<ClientModel>> getClients({String? search}) async {
    final query = search != null ? '?search=$search' : '';
    final resp = await _client.get('/artisans/customers$query');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => ClientModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClientModel> getClientById(String id) async {
    final resp = await _client.get('/artisans/customers/$id');
    return ClientModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<ClientModel> createClient(Map<String, dynamic> data) async {
    final resp = await _client.post('/artisans/customers', data: data);
    return ClientModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<ClientModel> updateClient(String id, Map<String, dynamic> data) async {
    final resp = await _client.patch('/artisans/customers/$id', data: data);
    return ClientModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteClient(String id) =>
      _client.delete('/artisans/customers/$id');

  Future<List<MeasurementModel>> getMeasurements(String clientId) async {
    final resp = await _client.get('/artisans/customers/$clientId');
    final customer =
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final values = customer['measurements'] as Map<String, dynamic>? ?? {};
    if (values.isEmpty) return [];
    return [
      MeasurementModel(
        id: '${clientId}-current',
        clientId: clientId,
        type: 'TAILLEUR',
        values: values.map((key, value) => MapEntry(
            key, value is num ? value.toDouble() : double.tryParse('$value') ?? 0)),
        notes: customer['notes'] as String?,
        createdAt: DateTime.tryParse(customer['updatedAt'] as String? ?? '') ??
            DateTime.now(),
      ),
    ];
  }

  Future<MeasurementModel> saveMeasurements(
      String clientId, Map<String, dynamic> data) async {
    final resp =
        await _client.patch('/artisans/customers/$clientId/measurements', data: data);
    final customer =
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
    final values = customer['measurements'] as Map<String, dynamic>? ?? {};
    return MeasurementModel(
      id: '${clientId}-current',
      clientId: clientId,
      type: 'TAILLEUR',
      values: values.map((key, value) => MapEntry(
          key, value is num ? value.toDouble() : double.tryParse('$value') ?? 0)),
      notes: customer['notes'] as String?,
      createdAt: DateTime.tryParse(customer['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
