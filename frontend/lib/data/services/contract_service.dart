import '../models/contract_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class ContractService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<ContractModel>> getContracts(int hostId) async {
    final res = await _dio.get(
      ApiConstants.contracts,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => ContractModel.fromJson(e))
        .toList();
  }

  Future<ContractModel> getContractDetail(int contractId) async {
    final res = await _dio.get('${ApiConstants.contracts}/$contractId');
    return ContractModel.fromJson(res.data['data']);
  }

  Future<ContractModel> createContract(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.contracts, data: data);
    return ContractModel.fromJson(res.data['data']);
  }

  Future<ContractModel> extendContract(
      int contractId, String newEndDate) async {
    final res = await _dio.put(
      '${ApiConstants.contracts}/$contractId/extend',
      data: {'newEndDate': newEndDate},
    );
    return ContractModel.fromJson(res.data['data']);
  }

  Future<void> terminateContract(int contractId, int terminatedById) async {
    await _dio.patch(
      '${ApiConstants.contracts}/$contractId/terminate',
      queryParameters: {'terminatedById': terminatedById},
    );
  }

  Future<void> addService(int contractId, int serviceId) async {
    await _dio.post('${ApiConstants.contracts}/$contractId/services/$serviceId');
  }

  Future<void> removeService(int contractId, int serviceId) async {
    await _dio.delete(
        '${ApiConstants.contracts}/$contractId/services/$serviceId');
  }
}