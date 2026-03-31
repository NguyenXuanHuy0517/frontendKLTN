import 'dart:io';

import 'package:dio/dio.dart';

import 'api_client.dart';

class AvatarUploadService {
  final _hostDio = ApiClient.instance.hostDio;
  final _tenantDio = ApiClient.instance.tenantDio;

  Future<String> upload({
    required File file,
    required int userId,
    required String role,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    if (role == 'HOST') {
      final res = await _hostDio.post(
        '/api/host/avatar',
        queryParameters: {'userId': userId},
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data['data'] as String;
    }

    final res = await _tenantDio.post(
      '/api/tenant/avatar',
      queryParameters: {'userId': userId},
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.data['data'] as String;
  }

  Future<void> remove({required int userId, required String role}) async {
    if (role == 'HOST') {
      await _hostDio.delete(
        '/api/host/avatar',
        queryParameters: {'userId': userId},
      );
      return;
    }

    await _tenantDio.delete(
      '/api/tenant/avatar',
      queryParameters: {'userId': userId},
    );
  }
}
