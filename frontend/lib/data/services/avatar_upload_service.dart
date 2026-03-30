import 'dart:io';
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import 'api_client.dart';

/// Service gọi API upload/xoá avatar cho cả HOST và TENANT.
class AvatarUploadService {
  final _hostDio = ApiClient.instance.hostDio;
  final _tenantDio = ApiClient.instance.hostDio; // dùng chung port nếu tenant dùng host upload

  /// Upload avatar cho HOST hoặc TENANT.
  ///
  /// - HOST → POST /api/host/avatar?userId=X  (multipart — host-service có Cloudinary)
  /// - TENANT → POST /api/host/upload/avatar  lấy URL, rồi PUT /api/tenant/avatar
  ///
  /// Trả về secure_url của ảnh mới.
  Future<String> upload({
    required File file,
    required int userId,
    required String role, // 'HOST' | 'TENANT'
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ),
    });

    if (role == 'HOST') {
      // HOST: upload trực tiếp, backend lưu vào DB luôn
      final res = await _hostDio.post(
        '/api/host/avatar',
        queryParameters: {'userId': userId},
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return res.data['data'] as String;
    } else {
      // TENANT: upload lên host-service để lấy URL, sau đó lưu vào tenant profile
      final uploadRes = await _hostDio.post(
        '/api/host/upload/avatar',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      final url = uploadRes.data['data'] as String;

      // Lưu URL vào tenant profile
      await _tenantDio.put(
        '/api/tenant/avatar',
        queryParameters: {'userId': userId},
        data: {'avatarUrl': url},
      );
      return url;
    }
  }

  /// Xoá avatar — đặt về null.
  Future<void> remove({required int userId, required String role}) async {
    if (role == 'HOST') {
      await _hostDio.delete(
        '/api/host/avatar',
        queryParameters: {'userId': userId},
      );
    } else {
      await _tenantDio.delete(
        '/api/tenant/avatar',
        queryParameters: {'userId': userId},
      );
    }
  }
}