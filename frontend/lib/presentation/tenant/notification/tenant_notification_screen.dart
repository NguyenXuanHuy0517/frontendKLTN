import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/services/api_client.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_badge_provider.dart';

class _NotificationModel {
  final int notificationId;
  final String type;
  final String title;
  final String body;
  final String? refType;
  final int? refId;
  final bool isRead;
  final String? createdAt;

  _NotificationModel({
    required this.notificationId,
    required this.type,
    required this.title,
    required this.body,
    this.refType,
    this.refId,
    required this.isRead,
    this.createdAt,
  });

  factory _NotificationModel.fromJson(Map<String, dynamic> json) {
    return _NotificationModel(
      notificationId: json['notificationId'] ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      refType: json['refType']?.toString(),
      refId: json['refId'] as int?,
      isRead: json['isRead'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }
}

class TenantNotificationScreen extends StatefulWidget {
  const TenantNotificationScreen({super.key});

  @override
  State<TenantNotificationScreen> createState() =>
      _TenantNotificationScreenState();
}

class _TenantNotificationScreenState extends State<TenantNotificationScreen> {
  int? _userId;
  List<_NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _syncUnreadBadge([int? count]) {
    if (!mounted) return;
    context.read<NotificationBadgeProvider>().setTenantUnreadCount(
          count ?? _notifications.where((item) => !item.isRead).length,
        );
  }

  Future<void> _load() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    setState(() {
      _userId = userId;
      _loading = true;
    });

    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final response = await ApiClient.instance.tenantDio.get(
        '/api/tenant/notifications',
        queryParameters: {'userId': userId},
      );

      final list = (response.data['data'] as List<dynamic>? ?? const [])
          .map(
            (item) => _NotificationModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();

      if (!mounted) return;
      setState(() => _notifications = list);
      _syncUnreadBadge(list.where((item) => !item.isRead).length);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Không tải được danh sách thông báo.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _markAllRead() async {
    if (_userId == null) return;

    try {
      await ApiClient.instance.tenantDio.patch(
        '/api/tenant/notifications/read-all',
        queryParameters: {'userId': _userId},
      );
      await _load();
    } catch (_) {}
  }

  Future<void> _markRead(int notificationId) async {
    if (_userId == null) return;

    try {
      await ApiClient.instance.tenantDio.patch(
        '/api/tenant/notifications/$notificationId/read',
        queryParameters: {'userId': _userId},
      );

      if (!mounted) return;
      setState(() {
        final index =
            _notifications.indexWhere((item) => item.notificationId == notificationId);
        if (index == -1) return;

        final current = _notifications[index];
        _notifications[index] = _NotificationModel(
          notificationId: current.notificationId,
          type: current.type,
          title: current.title,
          body: current.body,
          refType: current.refType,
          refId: current.refId,
          isRead: true,
          createdAt: current.createdAt,
        );
      });
      _syncUnreadBadge();
    } catch (_) {}
  }

  void _openNotification(_NotificationModel notification) {
    _markRead(notification.notificationId);

    if (notification.refType == 'INVOICE' && notification.refId != null) {
      context.push('/tenant/invoices/${notification.refId}');
      return;
    }

    if (notification.refType == 'CONTRACT') {
      context.push('/tenant/contract');
      return;
    }

    if (notification.refType == 'ISSUE' && notification.refId != null) {
      context.push('/tenant/issues/${notification.refId}');
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'INVOICE_DUE':
      case 'INVOICE_OVERDUE':
        return Icons.receipt_long_outlined;
      case 'CONTRACT_EXPIRING':
      case 'CONTRACT_EXPIRED':
        return Icons.description_outlined;
      case 'ISSUE_UPDATED':
        return Icons.report_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'INVOICE_DUE':
        return AppColors.warning;
      case 'INVOICE_OVERDUE':
        return AppColors.error;
      case 'CONTRACT_EXPIRING':
      case 'CONTRACT_EXPIRED':
        return AppColors.info;
      case 'ISSUE_UPDATED':
        return AppColors.success;
      default:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final unreadCount = _notifications.where((item) => !item.isRead).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông báo${unreadCount > 0 ? ' ($unreadCount)' : ''}',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Đọc hết',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const AppLoading()
          : _notifications.isEmpty
              ? const AppEmpty(
                  message: 'Chưa có thông báo nào.',
                  icon: Icons.notifications_outlined,
                )
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _load,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    separatorBuilder: (_, separatorIndex) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final notification = _notifications[index];
                      final color = _colorForType(notification.type);
                      final cardColor = notification.isRead
                          ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                          : color.withValues(alpha: 0.06);
                      final borderColor = notification.isRead
                          ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
                          : color.withValues(alpha: 0.25);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openNotification(notification),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    _iconForType(notification.type),
                                    color: color,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              notification.title,
                                              style: AppTextStyles.body.copyWith(
                                                color: fg,
                                                fontWeight: notification.isRead
                                                    ? FontWeight.w400
                                                    : FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          if (!notification.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              margin: const EdgeInsets.only(left: 8),
                                              decoration: BoxDecoration(
                                                color: color,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.body,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: subtext,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppDateUtils.timeAgo(notification.createdAt),
                                        style: AppTextStyles.caption.copyWith(
                                          color: subtext,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 0),
    );
  }
}
