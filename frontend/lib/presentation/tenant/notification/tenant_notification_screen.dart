import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../providers/auth_provider.dart';
import '../../../data/services/api_client.dart';

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

  factory _NotificationModel.fromJson(Map<String, dynamic> json) =>
      _NotificationModel(
        notificationId: json['notificationId'],
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        refType: json['refType'],
        refId: json['refId'],
        isRead: json['isRead'] ?? false,
        createdAt: json['createdAt'],
      );
}

class TenantNotificationScreen extends StatefulWidget {
  const TenantNotificationScreen({super.key});

  @override
  State<TenantNotificationScreen> createState() =>
      _TenantNotificationScreenState();
}

class _TenantNotificationScreenState
    extends State<TenantNotificationScreen> {
  int? _userId;
  List<_NotificationModel> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _userId = await context.read<AuthProvider>().getUserId();
    if (_userId == null || !mounted) return;
    setState(() => _loading = true);
    try {
      // FIX: dùng tenantDio thay vì hostDio
      final res = await ApiClient.instance.tenantDio.get(
        '/api/tenant/notifications',
        queryParameters: {'userId': _userId},
      );
      final list = (res.data['data'] as List)
          .map((e) => _NotificationModel.fromJson(e))
          .toList();
      if (mounted) setState(() => _notifications = list);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Không tải được thông báo'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
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
      setState(() {
        final idx = _notifications
            .indexWhere((n) => n.notificationId == notificationId);
        if (idx != -1) {
          final old = _notifications[idx];
          _notifications[idx] = _NotificationModel(
            notificationId: old.notificationId,
            type: old.type,
            title: old.title,
            body: old.body,
            refType: old.refType,
            refId: old.refId,
            isRead: true,
            createdAt: old.createdAt,
          );
        }
      });
    } catch (_) {}
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

  void _onTap(_NotificationModel n) {
    _markRead(n.notificationId);
    if (n.refType == 'INVOICE' && n.refId != null) {
      context.push('/tenant/invoices/${n.refId}');
    } else if (n.refType == 'CONTRACT') {
      context.push('/tenant/contract');
    } else if (n.refType == 'ISSUE' && n.refId != null) {
      context.push('/tenant/issues/${n.refId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final unread = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thông báo${unread > 0 ? ' ($unread)' : ''}',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: Text(
                'Đọc hết',
                style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: _loading
          ? const AppLoading()
          : _notifications.isEmpty
          ? const AppEmpty(
        message: 'Chưa có thông báo nào',
        icon: Icons.notifications_outlined,
      )
          : RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _notifications.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final n = _notifications[i];
            final color = _colorForType(n.type);
            final cardColor = n.isRead
                ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                : color.withOpacity(0.06);
            final borderColor = n.isRead
                ? (isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder)
                : color.withOpacity(0.25);

            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onTap(n),
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
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_iconForType(n.type),
                            color: color, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Expanded(
                                child: Text(
                                  n.title,
                                  style: AppTextStyles.body.copyWith(
                                    color: fg,
                                    fontWeight: n.isRead
                                        ? FontWeight.w400
                                        : FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (!n.isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(
                                      left: 8),
                                  decoration: BoxDecoration(
                                    color: color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                              n.body,
                              style: AppTextStyles.bodySmall
                                  .copyWith(color: subtext),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppDateUtils.timeAgo(n.createdAt),
                              style: AppTextStyles.caption
                                  .copyWith(color: subtext),
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
      bottomNavigationBar: const TenantBottomNav(currentIndex: -1),
    );
  }
}