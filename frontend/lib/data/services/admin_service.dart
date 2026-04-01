import '../../core/constants/api_constants.dart';
import '../models/admin_dashboard_model.dart';
import '../models/admin_host_model.dart';
import '../models/admin_revenue_model.dart';
import '../models/admin_room_audit_model.dart';
import 'api_client.dart';

class AdminService {
  final _dio = ApiClient.instance.adminDio;

  Future<AdminDashboardModel> getDashboard() async {
    final res = await _dio.get(ApiConstants.adminDashboard);
    return AdminDashboardModel.fromJson(res.data['data']);
  }

  Future<List<AdminHostModel>> getHosts({
    String? status,
    String? keyword,
  }) async {
    final queryParameters = <String, dynamic>{};
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (keyword != null && keyword.isNotEmpty) {
      queryParameters['keyword'] = keyword;
    }

    final res = await _dio.get(
      ApiConstants.adminHosts,
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    return (res.data['data'] as List)
        .map((e) => AdminHostModel.fromJson(e))
        .toList();
  }

  Future<AdminHostModel> getHostDetail(int hostId) async {
    final res = await _dio.get('${ApiConstants.adminHosts}/$hostId');
    return AdminHostModel.fromJson(res.data['data']);
  }

  Future<void> updateHostStatus(
    int hostId, {
    required bool active,
    required String reason,
    String? note,
  }) async {
    await _dio.patch(
      '${ApiConstants.adminHosts}/$hostId/status',
      data: {
        'active': active,
        'reason': reason,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
  }

  Future<List<AdminRoomAuditModel>> getRooms() async {
    final res = await _dio.get(ApiConstants.adminRooms);
    return (res.data['data'] as List)
        .map((e) => AdminRoomAuditModel.fromJson(e))
        .toList();
  }

  Future<List<AdminRoomAuditModel>> getRoomsWithoutInvoice() async {
    final res = await _dio.get(ApiConstants.adminRoomsWithoutInvoice);
    return (res.data['data'] as List)
        .map((e) => AdminRoomAuditModel.fromJson(e))
        .toList();
  }

  Future<AdminRevenueModel> getRevenue(String period) async {
    final res = await _dio.get(
      ApiConstants.adminRevenue,
      queryParameters: {'period': period},
    );
    return AdminRevenueModel.fromJson(res.data['data']);
  }
}
