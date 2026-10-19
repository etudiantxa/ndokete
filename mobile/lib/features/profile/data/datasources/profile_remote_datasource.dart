import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/profile_model.dart';

class ProfileRemoteDatasource {
  final ApiClient _client;
  ProfileRemoteDatasource(this._client);

  Future<ProfileModel> getProfile() async {
    final resp = await _client.get('/users/me');
    return ProfileModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<ProfileModel> updateProfile(Map<String, dynamic> data) async {
    final resp = await _client.patch('/users/me', data: data);
    return ProfileModel.fromJson(
        (resp.data as Map<String, dynamic>)['data'] as Map<String, dynamic>);
  }

  Future<String> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final resp = await _client.post('/uploads/image', data: formData);
    final url = (resp.data as Map)['url'] as String;
    await _client.patch('/users/me', data: {'profilePhoto': url});
    return url;
  }

  Future<void> changePassword(String current, String newPassword) =>
      _client.post('/users/me/password', data: {
        'currentPassword': current,
        'newPassword': newPassword,
      });

  Future<void> deleteAccount() => _client.delete('/users/me');
}
