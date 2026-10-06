import '../../../../core/network/api_client.dart';
import '../models/product_model.dart';

class MarketplaceRemoteDatasource {
  final ApiClient _client;
  MarketplaceRemoteDatasource(this._client);

  Future<List<ProductModel>> getProducts({String? category, String? search}) async {
    final params = <String>[];
    if (category != null) params.add('category=$category');
    if (search != null) params.add('search=$search');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final resp = await _client.get('/marketplace$query');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> getProductById(String id) async {
    final resp = await _client.get('/marketplace/products/$id');
    return ProductModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<List<ProductModel>> getMyProducts() async {
    final resp = await _client.get('/marketplace/my-shop');
    final data = (resp.data as Map<String, dynamic>)['data'] as List<dynamic>;
    return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProductModel> createProduct(Map<String, dynamic> data) async {
    final resp = await _client.post('/marketplace/products', data: data);
    return ProductModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<ProductModel> updateProduct(String id, Map<String, dynamic> data) async {
    final resp = await _client.patch('/marketplace/products/$id', data: data);
    return ProductModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<void> deleteProduct(String id) =>
      _client.delete('/marketplace/products/$id');

  Future<void> placeOrder(String productId, int quantity) async {
    await _client.post('/marketplace/orders', data: {
      'items': [
        {'productId': productId, 'quantity': quantity}
      ],
    });
  }
}
