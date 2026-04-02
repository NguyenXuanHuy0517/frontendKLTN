import '../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class TenantNotificationService {
  final _dio = ApiClient.instance.tenantDio;

  Future<PagedResult<NotificationModel>> getNotificationsPage({
    required int userId,
    bool? isRead,
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final res = await _dio.get(
      '${ApiConstants.tenantNotifications}/paged',
      queryParameters: {
        'userId': userId,
        'page': page,
        'size': size,
        'sort': sort,
        if (isRead != null) 'isRead': isRead,
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );

    return PagedResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
      NotificationModel.fromJson,
    );
  }

  Future<int> getUnreadCount(int userId) async {
    final res = await _dio.get(
      '${ApiConstants.tenantNotifications}/unread-count',
      queryParameters: {'userId': userId},
    );
    final data = res.data['data'];
    if (data is int) return data;
    if (data is num) return data.toInt();
    return int.tryParse('$data') ?? 0;
  }

  Future<void> markAsRead(int notificationId, int userId) async {
    await _dio.patch(
      '${ApiConstants.tenantNotifications}/$notificationId/read',
      queryParameters: {'userId': userId},
    );
  }

  Future<void> markAllAsRead(int userId) async {
    await _dio.patch(
      '${ApiConstants.tenantNotifications}/read-all',
      queryParameters: {'userId': userId},
    );
  }
}
