import '../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class HostNotificationService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<NotificationModel>> getNotifications(int userId) async {
    final res = await _dio.get(
      ApiConstants.hostNotifications,
      queryParameters: {'userId': userId},
    );

    return (res.data['data'] as List<dynamic>? ?? const [])
        .map((item) => NotificationModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<PagedResult<NotificationModel>> getNotificationsPage({
    required int userId,
    bool? isRead,
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final res = await _dio.get(
      '${ApiConstants.hostNotifications}/paged',
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
      '${ApiConstants.hostNotifications}/unread-count',
      queryParameters: {'userId': userId},
    );
    final data = res.data['data'];
    if (data is int) return data;
    if (data is num) return data.toInt();
    return int.tryParse('$data') ?? 0;
  }

  Future<void> markAsRead(int notificationId) async {
    await _dio.patch('${ApiConstants.hostNotifications}/$notificationId/read');
  }

  Future<void> markAllAsRead(int userId) async {
    await _dio.patch(
      '${ApiConstants.hostNotifications}/mark-all-read',
      queryParameters: {'userId': userId},
    );
  }

  Future<void> sendNotification({
    required int hostId,
    int? tenantId,
    required String type,
    required String title,
    required String body,
    String? refType,
    int? refId,
  }) async {
    final payload = <String, dynamic>{
      'type': type,
      'title': title,
      'body': body,
      ...?tenantId == null ? null : {'tenantId': tenantId},
      ...?(refType?.isNotEmpty ?? false) ? {'refType': refType} : null,
      ...?refId == null ? null : {'refId': refId},
    };

    await _dio.post(
      '${ApiConstants.hostNotifications}/send',
      queryParameters: {'hostId': hostId},
      data: payload,
    );
  }
}
