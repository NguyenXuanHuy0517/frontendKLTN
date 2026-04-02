import '../../core/constants/api_constants.dart';
import '../models/tenant_dashboard_summary_model.dart';
import 'api_client.dart';

class TenantDashboardService {
  final _dio = ApiClient.instance.tenantDio;

  Future<TenantDashboardSummaryModel> getSummary(int userId) async {
    final response = await _dio.get(
      ApiConstants.tenantDashboardSummary,
      queryParameters: {'userId': userId},
    );
    return TenantDashboardSummaryModel.fromJson(
      Map<String, dynamic>.from(response.data['data'] as Map),
    );
  }
}
