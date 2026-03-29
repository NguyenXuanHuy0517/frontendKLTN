import '../models/report_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class ReportService {
  final _dio = ApiClient.instance.hostDio;

  Future<ReportModel> getDashboard(int hostId) async {
    final res = await _dio.get(
      ApiConstants.reports,
      queryParameters: {'hostId': hostId},
    );
    return ReportModel.fromJson(res.data['data']);
  }
}