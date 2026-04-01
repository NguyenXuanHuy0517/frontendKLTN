import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../models/contract_model.dart';
import '../models/service_model.dart';
import 'api_client.dart';

class TenantSubscriptionService {
  final _dio = ApiClient.instance.tenantDio;

  Future<ContractModel?> getCurrentContract(int userId) async {
    try {
      final res = await _dio.get(
        '${ApiConstants.tenantContracts}/current',
        queryParameters: {'userId': userId},
      );
      final data = res.data['data'];
      if (data == null) return null;
      return ContractModel.fromTenantJson(data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<ServiceModel>> getContractServices(int contractId) async {
    final res = await _dio.get('/api/tenant/services/$contractId');
    return (res.data['data'] as List)
        .map((item) => ServiceModel.fromTenantJson(item))
        .toList();
  }

  Future<List<ServiceModel>> getAvailableServices(int contractId) async {
    final res = await _dio.get('/api/tenant/services/available/$contractId');
    return (res.data['data'] as List)
        .map((item) => ServiceModel.fromTenantJson(item))
        .toList();
  }

  Future<void> addService({
    required int userId,
    required int contractId,
    required int serviceId,
    int quantity = 1,
  }) async {
    await _dio.post(
      '/api/tenant/services/add',
      queryParameters: {'userId': userId},
      data: {
        'contractId': contractId,
        'serviceId': serviceId,
        'quantity': quantity,
      },
    );
  }

  Future<void> updateQuantity({
    required int userId,
    required int contractId,
    required int serviceId,
    required int quantity,
  }) async {
    await _dio.patch(
      '/api/tenant/services/$contractId/services/$serviceId',
      queryParameters: {'userId': userId},
      data: {'quantity': quantity},
    );
  }

  Future<void> removeService({
    required int userId,
    required int contractId,
    required int serviceId,
  }) async {
    await _dio.delete(
      '/api/tenant/services/$contractId/services/$serviceId',
      queryParameters: {'userId': userId},
    );
  }
}
