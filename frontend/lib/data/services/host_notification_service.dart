import '../../core/constants/api_constants.dart';
import '../models/notification_model.dart';
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
      if (tenantId != null) 'tenantId': tenantId,
      if (refType != null && refType.isNotEmpty) 'refType': refType,
      if (refId != null) 'refId': refId,
    };

    await _dio.post(
      '${ApiConstants.hostNotifications}/send',
      queryParameters: {'hostId': hostId},
      data: payload,
    );
  }
}
