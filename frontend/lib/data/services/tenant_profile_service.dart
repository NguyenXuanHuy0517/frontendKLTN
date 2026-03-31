import '../../core/constants/api_constants.dart';
import '../models/tenant_profile_model.dart';
import 'api_client.dart';

class TenantProfileService {
  final _dio = ApiClient.instance.tenantDio;

  Future<TenantProfileModel> getProfile(int userId) async {
    final res = await _dio.get(
      ApiConstants.tenantProfile,
      queryParameters: {'userId': userId},
    );
    return TenantProfileModel.fromJson(res.data['data']);
  }

  Future<TenantProfileModel> updateProfile({
    required int userId,
    required String fullName,
    required String phoneNumber,
    String? avatarUrl,
  }) async {
    final payload = <String, dynamic>{
      'fullName': fullName,
      'phoneNumber': phoneNumber,
    };

    if (avatarUrl != null) {
      payload['avatarUrl'] = avatarUrl;
    }

    final res = await _dio.put(
      ApiConstants.tenantProfile,
      queryParameters: {'userId': userId},
      data: payload,
    );
    return TenantProfileModel.fromJson(res.data['data']);
  }
}
