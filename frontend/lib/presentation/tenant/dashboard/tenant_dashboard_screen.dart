import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/session/session_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_popup_window.dart';
import '../../../core/widgets/dashboard_clock_card.dart';
import '../../../core/widgets/error_retry_widget.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/notification_badge.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/widgets/tenant_bottom_nav.dart';
import '../../../data/models/contract_model.dart';
import '../../../data/models/tenant_dashboard_summary_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_badge_provider.dart';
import '../../../providers/tenant_dashboard_provider.dart';
import '../../../providers/theme_provider.dart';
import '../profile/tenant_profile_screen.dart';

class TenantDashboardScreen extends StatefulWidget {
  const TenantDashboardScreen({super.key});

  @override
  State<TenantDashboardScreen> createState() => _TenantDashboardScreenState();
}

class _TenantDashboardScreenState extends State<TenantDashboardScreen> {
  int? _userId;
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final userId = await auth.getUserId();
    final fullName = auth.user?.fullName.trim().isNotEmpty == true
        ? auth.user!.fullName.trim()
        : (SessionStore.instance.fullName ?? '').trim();

    if (!mounted) return;
    setState(() {
      _userId = userId;
      _fullName = fullName;
    });

    if (userId == null) return;

    await context.read<TenantDashboardProvider>().fetchSummary(userId);
    if (!mounted) return;
    final summary = context.read<TenantDashboardProvider>().summary;
    if (summary != null) {
      context.read<NotificationBadgeProvider>().setTenantUnreadCount(
        summary.unreadCount,
      );
    }
  }

  Future<void> _openProfilePopup() async {
    await AppPopupWindow.show(
      context,
      child: const TenantProfileScreen(showNavigation: false),
    );
    if (!mounted) return;
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final dashboard = context
        .select<
          TenantDashboardProvider,
          ({TenantDashboardSummaryModel? summary, bool loading, String? error})
        >(
          (provider) => (
            summary: provider.summary,
            loading: provider.loading,
            error: provider.error,
          ),
        );
    final summary = dashboard.summary;
    final unreadCount = context.select<NotificationBadgeProvider, int>(
      (provider) => provider.tenantUnreadCount,
    );
    final currentContract = summary?.currentContract;
    final unpaidCount = summary?.unpaidCount ?? 0;
    final overdueCount = summary?.overdueCount ?? 0;
    final openIssueCount = summary?.openIssueCount ?? 0;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _TenantDashboardTopBar(
                  isDark: isDark,
                  subtext: subtext,
                  unreadCount: unreadCount,
                  userId: _userId,
                  onProfileTap: _openProfilePopup,
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style: AppTextStyles.body.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 4),
                      if (_fullName.isNotEmpty) ...[
                        Text(
                          _fullName,
                          style: AppTextStyles.h2.copyWith(color: fg),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        'Trang chủ của bạn',
                        style: AppTextStyles.h1.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ),
              if (dashboard.loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoading(),
                )
              else if (dashboard.error != null && summary == null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorRetryWidget(
                    message: dashboard.error!,
                    onRetry: _load,
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 8,
                            child: _CurrentRoomCard(
                              contract: currentContract,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            flex: 5,
                            child: DashboardClockCard(compact: true),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _AlertCard(
                              label: 'Chưa thanh toán',
                              count: unpaidCount + overdueCount,
                              icon: Icons.receipt_long_outlined,
                              color: overdueCount > 0
                                  ? AppColors.error
                                  : AppColors.warning,
                              onTap: () => context.push('/tenant/invoices'),
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AlertCard(
                              label: 'Khiếu nại mở',
                              count: openIssueCount,
                              icon: Icons.report_outlined,
                              color: AppColors.warning,
                              onTap: () => context.push('/tenant/issues'),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Truy cập nhanh',
                        style: AppTextStyles.h3.copyWith(color: fg),
                      ),
                      const SizedBox(height: 12),
                      _QuickActions(
                        unreadCount: unreadCount,
                        onProfileTap: _openProfilePopup,
                        onNotificationVisited: () async {
                          if (_userId == null) return;
                          await context
                              .read<NotificationBadgeProvider>()
                              .refreshTenant(_userId!);
                        },
                      ),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const TenantBottomNav(currentIndex: 0),
    );
  }
}

class _TenantDashboardTopBar extends StatelessWidget {
  final bool isDark;
  final Color subtext;
  final int unreadCount;
  final int? userId;
  final Future<void> Function() onProfileTap;

  const _TenantDashboardTopBar({
    required this.isDark,
    required this.subtext,
    required this.unreadCount,
    required this.userId,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.gradient),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          GradientText(
            'SmartRoom',
            style: AppTextStyles.h3,
            colors: AppColors.gradient,
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: subtext,
              size: 22,
            ),
            onPressed: () => context.read<ThemeProvider>().toggleTheme(),
          ),
          IconButton(
            icon: NotificationBadge(
              showBadge: unreadCount > 0,
              child: Icon(
                Icons.notifications_outlined,
                color: subtext,
                size: 22,
              ),
            ),
            onPressed: () async {
              await context.push('/tenant/notifications');
              if (!context.mounted || userId == null) return;
              await context.read<NotificationBadgeProvider>().refreshTenant(
                userId!,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.person_outline_rounded, color: subtext, size: 22),
            onPressed: onProfileTap,
          ),
        ],
      ),
    );
  }
}

class _CurrentRoomCard extends StatelessWidget {
  final ContractModel? contract;
  final bool isDark;

  const _CurrentRoomCard({this.contract, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    if (contract == null) {
      return AppCard(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: subtext.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.meeting_room_outlined, color: subtext),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chưa có hợp đồng',
                    style: AppTextStyles.body.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Liên hệ chủ trọ để cập nhật hợp đồng thuê phòng.',
                    style: AppTextStyles.bodySmall.copyWith(color: subtext),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final endDate = DateTime.tryParse(contract!.endDate);
    final daysLeft = endDate?.difference(DateTime.now()).inDays;
    final expiringSoon = daysLeft != null && daysLeft >= 0 && daysLeft <= 30;

    return AppCard(
      featured: true,
      onTap: () => context.push('/tenant/contract'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.meeting_room_outlined,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phòng ${contract!.roomCode}',
                      style: AppTextStyles.h3.copyWith(color: fg),
                    ),
                    Text(
                      contract!.areaName,
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: contract!.status),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: border, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá thuê',
                      style: AppTextStyles.caption.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      CurrencyUtils.format(contract!.actualRentPrice),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (daysLeft != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Kết thúc HĐ',
                        style: AppTextStyles.caption.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppDateUtils.formatDate(contract!.endDate),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: expiringSoon ? AppColors.warning : fg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          if (expiringSoon) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Còn $daysLeft ngày hết hạn, vui lòng liên hệ chủ trọ nếu cần gia hạn.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isDark;

  const _AlertCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      onTap: onTap,
      featured: count > 0,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: AppTextStyles.h3.copyWith(color: fg)),
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(color: subtext),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final int unreadCount;
  final Future<void> Function() onProfileTap;
  final Future<void> Function() onNotificationVisited;

  const _QuickActions({
    required this.unreadCount,
    required this.onProfileTap,
    required this.onNotificationVisited,
  });

  static const _actions = [
    _Action(Icons.receipt_long_outlined, 'Hóa đơn', '/tenant/invoices'),
    _Action(Icons.description_outlined, 'Hợp đồng', '/tenant/contract'),
    _Action(Icons.report_outlined, 'Khiếu nại', '/tenant/issues'),
    _Action(
      Icons.miscellaneous_services_outlined,
      'Dịch vụ',
      '/tenant/services',
    ),
    _Action(Icons.notifications_outlined, 'Thông báo', '/tenant/notifications'),
    _Action(Icons.person_outline_rounded, 'Hồ sơ', '/tenant/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    const spacing = 12.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 720
            ? 4
            : width >= 440
            ? 3
            : 2;
        final itemWidth =
            (width - spacing * (crossAxisCount - 1)) / crossAxisCount;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: _actions.map((action) {
            final isNotification = action.route == '/tenant/notifications';
            final isProfile = action.route == '/tenant/profile';

            return SizedBox(
              width: itemWidth,
              child: AspectRatio(
                aspectRatio: 1,
                child: AppCard(
                  onTap: () async {
                    if (isProfile) {
                      await onProfileTap();
                      return;
                    }

                    await context.push(action.route);
                    if (!context.mounted || !isNotification) return;
                    await onNotificationVisited();
                  },
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NotificationBadge(
                        showBadge: isNotification && unreadCount > 0,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            action.icon,
                            color: AppColors.accent,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        action.label,
                        style: AppTextStyles.caption.copyWith(color: fg),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final String route;

  const _Action(this.icon, this.label, this.route);
}
