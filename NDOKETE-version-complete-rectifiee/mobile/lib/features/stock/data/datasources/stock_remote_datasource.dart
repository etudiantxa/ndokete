import '../../../../core/network/api_client.dart';
import '../models/stock_model.dart';

class StockRemoteDatasource {
  final ApiClient _client;
  StockRemoteDatasource(this._client);

  Future<List<StockItemModel>> getStockItems({String? category}) async {
    final query = category != null ? '?category=$category' : '';
    final resp = await _client.get('/artisans/stock$query');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => StockItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<StockItemModel> getStockItemById(String id) async {
    final resp = await _client.get('/artisans/stock/$id');
    return StockItemModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<StockItemModel> createStockItem(Map<String, dynamic> data) async {
    final resp = await _client.post('/artisans/stock', data: data);
    return StockItemModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<StockItemModel> updateStockItem(String id, Map<String, dynamic> data) async {
    final resp = await _client.patch('/artisans/stock/$id', data: data);
    return StockItemModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteStockItem(String id) => _client.delete('/artisans/stock/$id');

  Future<StockItemModel> adjustStock(
      String id, double quantity, String type, String? reason) async {
    final resp = await _client.post('/artisans/stock/$id/adjust', data: {
      'quantity': quantity,
      'type': type,
      if (reason != null) 'reason': reason,
    });
    return StockItemModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<List<StockItemModel>> getLowStockItems() async {
    final resp = await _client.get('/artisans/stock/alerts');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => StockItemModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
