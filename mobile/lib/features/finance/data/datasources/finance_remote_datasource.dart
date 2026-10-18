import '../../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

class FinanceRemoteDatasource {
  final ApiClient _client;
  FinanceRemoteDatasource(this._client);

  Future<TreasurySummaryModel> getTreasurySummary({String? period}) async {
    final query = period != null ? '?period=$period' : '';
    final resp = await _client.get('/artisans/transactions/treasury$query');
    return TreasurySummaryModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<List<TransactionModel>> getTransactions({String? type, String? period}) async {
    final params = <String>[];
    if (type != null) params.add('type=$type');
    if (period != null) params.add('period=$period');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final resp = await _client.get('/artisans/transactions$query');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => TransactionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TransactionModel> createTransaction(Map<String, dynamic> data) async {
    final resp = await _client.post('/artisans/transactions', data: data);
    return TransactionModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteTransaction(String id) =>
      _client.delete('/artisans/transactions/$id');

  Future<Map<String, dynamic>> generateReport(
      String startDate, String endDate) async {
    final start = DateTime.parse(startDate);
    final resp = await _client.get(
        '/artisans/transactions/report/${start.year}/${start.month}');
    return (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>;
  }
}
