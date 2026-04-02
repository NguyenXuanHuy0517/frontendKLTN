import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/list_search_field.dart';
import '../../../core/widgets/paged_load_more.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/notification_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_badge_provider.dart';
import '../../../providers/tenant_notification_list_provider.dart';

class TenantNotificationScreen extends StatefulWidget {
  const TenantNotificationScreen({super.key});

  @override
  State<TenantNotificationScreen> createState() =>
      _TenantNotificationScreenState();
}

class _TenantNotificationScreenState extends State<TenantNotificationScreen> {
  final _searchController = TextEditingController();
  final _readFilters = const [
    _ReadFilterOption(label: 'Tat ca', value: null),
    _ReadFilterOption(label: 'Chua doc', value: false),
    _ReadFilterOption(label: 'Da doc', value: true),
  ];

  Timer? _searchDebounce;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _syncUnreadBadge([int? count]) {
    if (!mounted) return;
    context.read<NotificationBadgeProvider>().setTenantUnreadCount(
      count ?? context.read<TenantNotificationListProvider>().unreadCount,
    );
  }

  Future<void> _bootstrap() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    if (userId == null) {
      setState(() {
        _bootstrapError = 'Khong xac dinh duoc tai khoan nguoi thue hien tai.';
      });
      return;
    }

    final provider = context.read<TenantNotificationListProvider>();
    _searchController.text = provider.search;
    await provider.bootstrap(userId: userId);
    _syncUnreadBadge(provider.unreadCount);
  }

  Future<void> _markAllRead() async {
    await context.read<TenantNotificationListProvider>().markAllAsRead();
    _syncUnreadBadge();
  }

  Future<void> _markRead(int notificationId) async {
    await context.read<TenantNotificationListProvider>().markAsRead(
      notificationId,
    );
    _syncUnreadBadge();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => context.read<TenantNotificationListProvider>().applyFilters(
        isRead: context.read<TenantNotificationListProvider>().isRead,
        search: value,
      ),
    );
  }

  Future<void> _openNotification(NotificationModel notification) async {
    if (!notification.isRead) {
      await _markRead(notification.notificationId);
    }

    final refType = (notification.refType ?? '').toUpperCase();
    if (refType == 'INVOICE' && notification.refId != null) {
      context.push('/tenant/invoices/${notification.refId}');
      return;
    }

    if (refType == 'CONTRACT') {
      context.push('/tenant/contract');
      return;
    }

    if (refType == 'ISSUE' && notification.refId != null) {
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
    final unreadCount = context.select<TenantNotificationListProvider, int>(
      (provider) => provider.unreadCount,
    );
    final markingAllRead = context.select<TenantNotificationListProvider, bool>(
      (provider) => provider.markingAllRead,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Thong bao${unreadCount > 0 ? ' ($unreadCount)' : ''}',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: markingAllRead ? null : _markAllRead,
              child: Text(
                markingAllRead ? 'Dang xu ly...' : 'Doc het',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _buildBody(isDark, subtext),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody(bool isDark, Color subtext) {
    if (_bootstrapError != null) {
      return ErrorRetryWidget(message: _bootstrapError!, onRetry: _bootstrap);
    }

    final provider = context.watch<TenantNotificationListProvider>();
    final state = provider.state;

    if (state.loading) {
      return const AppLoading();
    }

    if (state.error != null) {
      return ErrorRetryWidget(
        message: state.error!,
        onRetry: () => context.read<TenantNotificationListProvider>().refresh(),
      );
    }

    return RefreshIndicator(
      color: AppColors.accent,
      onRefresh: () => context.read<TenantNotificationListProvider>().refresh(),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        itemCount:
            2 +
            (state.items.isEmpty ? 1 : state.items.length) +
            ((state.hasNext || state.loadingMore) ? 1 : 0),
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              ListSearchField(
                controller: _searchController,
                hintText: 'Tìm trong thông báo...',
                onChanged: _onSearchChanged,
              ),
            );
          }

          if (index == 1) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _readFilters
                    .map(
                      (filter) => ChoiceChip(
                        label: Text(filter.label),
                        selected: provider.isRead == filter.value,
                        onSelected: (_) {
                          context
                              .read<TenantNotificationListProvider>()
                              .applyFilters(
                                isRead: filter.value,
                                search: _searchController.text,
                              );
                        },
                      ),
                    )
                    .toList(),
              ),
            );
          }

          if (state.items.isEmpty) {
            return const AppEmpty(
              message: 'Chua co thong bao nao.',
              icon: Icons.notifications_outlined,
            );
          }

          final itemIndex = index - 2;
          if (itemIndex == state.items.length) {
            return PagedLoadMore(
              loading: state.loadingMore,
              hasNext: state.hasNext,
              onPressed: () =>
                  context.read<TenantNotificationListProvider>().loadMore(),
            );
          }

          final notification = state.items[itemIndex];
          final color = _colorForType(notification.type);
          final cardColor = notification.isRead
              ? (isDark ? AppColors.darkCard : AppColors.lightCard)
              : color.withValues(alpha: 0.06);
          final borderColor = notification.isRead
              ? (isDark ? AppColors.darkBorder : AppColors.lightBorder)
              : color.withValues(alpha: 0.25);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
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
                                      color: isDark
                                          ? AppColors.darkFg
                                          : AppColors.lightFg,
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
            ),
          );
        },
      ),
    );
  }
}

class _ReadFilterOption {
  final String label;
  final bool? value;

  const _ReadFilterOption({required this.label, required this.value});
}
