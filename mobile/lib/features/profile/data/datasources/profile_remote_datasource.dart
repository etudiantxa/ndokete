import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:cross_file/cross_file.dart';
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
    late final MultipartFile multipartFile;
    if (kIsWeb) {
      final xFile = XFile(filePath);
      final bytes = await xFile.readAsBytes();
      multipartFile = MultipartFile.fromBytes(bytes, filename: 'avatar.jpg');
    } else {
      multipartFile = await MultipartFile.fromFile(filePath);
    }

    final formData = FormData.fromMap({
      'file': multipartFile,
    });
    final resp = await _client.post('/uploads/image', data: formData);
    final resMap = resp.data as Map;
    final url = (resMap['data'] != null && resMap['data'] is Map)
        ? resMap['data']['url'] as String? ?? resMap['url'] as String? ?? ''
        : resMap['url'] as String? ?? '';
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
