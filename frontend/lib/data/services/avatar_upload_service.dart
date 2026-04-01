import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import 'api_client.dart';

class AvatarUploadService {
  final _hostDio   = ApiClient.instance.hostDio;
  final _tenantDio = ApiClient.instance.tenantDio;

  /// Upload ảnh avatar lên server và nhận về URL Cloudinary.
  /// [role] phải là 'HOST' hoặc 'TENANT'.
  Future<String> upload({
    required XFile file,
    required int userId,
    required String role,
  }) async {
    final fileBytes = await file.readAsBytes();
    final filename = file.name.isNotEmpty
        ? file.name
        : 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
    });

    final dio      = role == 'HOST' ? _hostDio : _tenantDio;
    final endpoint = role == 'HOST'
        ? '/api/host/avatar'
        : ApiConstants.tenantAvatar;

    final res = await dio.post(
      endpoint,
      queryParameters: {'userId': userId},
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    // Backend trả về ApiResponse<String>
    // { "success": true, "data": "https://res.cloudinary.com/..." }
    final data = res.data;
    if (data == null) {
      throw Exception('Upload avatar: server trả về null');
    }

    // Kiểm tra success flag
    if (data['success'] == false) {
      final msg = data['message'] ?? 'Upload thất bại';
      throw Exception(msg);
    }

    final url = data['data'];
    if (url == null || (url is String && url.isEmpty)) {
      throw Exception('Upload avatar: không nhận được URL từ server');
    }

    return url as String;
  }

  /// Xóa avatar — đặt lại về null.
  Future<void> remove({required int userId, required String role}) async {
    final dio      = role == 'HOST' ? _hostDio : _tenantDio;
    final endpoint = role == 'HOST'
        ? '/api/host/avatar'
        : ApiConstants.tenantAvatar;

    await dio.delete(
      endpoint,
      queryParameters: {'userId': userId},
    );
  }
}
