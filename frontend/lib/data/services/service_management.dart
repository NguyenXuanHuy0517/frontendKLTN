import '../models/service_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class ServiceManagement {
  final _dio = ApiClient.instance.hostDio;

  Future<List<ServiceModel>> getServices(int areaId) async {
    final res = await _dio.get('/api/host/areas/$areaId/services');
    return (res.data['data'] as List)
        .map((e) => ServiceModel.fromJson(e))
        .toList();
  }

  Future<ServiceModel> createService(
    int areaId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.post('/api/host/areas/$areaId/services', data: data);
    return ServiceModel.fromJson(res.data['data']);
  }

  Future<ServiceModel> updateService(
    int serviceId,
    Map<String, dynamic> data,
  ) async {
    final res = await _dio.put(
      '${ApiConstants.services}/$serviceId',
      data: data,
    );
    return ServiceModel.fromJson(res.data['data']);
  }

  Future<void> deleteService(int serviceId) async {
    await _dio.delete('${ApiConstants.services}/$serviceId');
  }
}
