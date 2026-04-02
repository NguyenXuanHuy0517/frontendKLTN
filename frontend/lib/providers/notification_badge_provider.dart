import 'package:flutter/material.dart';

import '../data/services/api_client.dart';
import '../data/services/host_notification_service.dart';

class NotificationBadgeProvider extends ChangeNotifier {
  final _hostNotificationService = HostNotificationService();

  int _hostUnreadCount = 0;
  int _tenantUnreadCount = 0;

  int get hostUnreadCount => _hostUnreadCount;
  int get tenantUnreadCount => _tenantUnreadCount;

  Future<void> refreshHost(int userId) async {
    try {
      setHostUnreadCount(await _hostNotificationService.getUnreadCount(userId));
    } catch (_) {}
  }

  Future<void> refreshTenant(int userId) async {
    try {
      final response = await ApiClient.instance.tenantDio.get(
        '/api/tenant/notifications/unread-count',
        queryParameters: {'userId': userId},
      );
      final data = response.data['data'];
      setTenantUnreadCount(
        data is int
            ? data
            : (data is num ? data.toInt() : int.tryParse('$data') ?? 0),
      );
    } catch (_) {}
  }

  void setHostUnreadCount(int count) {
    if (_hostUnreadCount == count) return;
    _hostUnreadCount = count;
    notifyListeners();
  }

  void setTenantUnreadCount(int count) {
    if (_tenantUnreadCount == count) return;
    _tenantUnreadCount = count;
    notifyListeners();
  }

  void reset() {
    if (_hostUnreadCount == 0 && _tenantUnreadCount == 0) return;
    _hostUnreadCount = 0;
    _tenantUnreadCount = 0;
    notifyListeners();
  }
}
