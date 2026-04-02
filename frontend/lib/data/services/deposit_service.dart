import '../models/deposit_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class DepositService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<DepositModel>> getDeposits(int hostId) async {
    final res = await _dio.get(
      ApiConstants.deposits,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => DepositModel.fromJson(e))
        .toList();
  }

  Future<DepositModel> createDeposit(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.deposits, data: data);
    return DepositModel.fromJson(res.data['data']);
  }

  Future<void> confirmDeposit(int depositId, int confirmedById) async {
    await _dio.patch(
      '${ApiConstants.deposits}/$depositId/confirm',
      queryParameters: {'confirmedById': confirmedById},
    );
  }

  Future<void> refundDeposit(int depositId) async {
    await _dio.patch('${ApiConstants.deposits}/$depositId/refund');
  }
}
