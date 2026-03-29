import '../models/tenant_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class TenantService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<TenantModel>> getTenants(int hostId) async {
    final res = await _dio.get(
      ApiConstants.tenants,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => TenantModel.fromJson(e))
        .toList();
  }

  Future<TenantModel> getTenantDetail(int tenantId) async {
    final res = await _dio.get('${ApiConstants.tenants}/$tenantId');
    return TenantModel.fromJson(res.data['data']);
  }

  Future<TenantModel> createTenant(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.tenants, data: data);
    return TenantModel.fromJson(res.data['data']);
  }

  Future<void> toggleActive(int tenantId) async {
    await _dio.patch('${ApiConstants.tenants}/$tenantId/toggle');
  }
}