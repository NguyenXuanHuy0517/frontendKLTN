// Màn hình tổng quan chính của host với số liệu, thao tác nhanh và điều hướng phụ.
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/storage_keys.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_popup_window.dart';
import '../../../core/widgets/dashboard_clock_card.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/notification_badge.dart';
import '../../../core/widgets/profile_bottom_sheet.dart';
import '../../../core/widgets/section_badge.dart';
import '../../../data/models/report_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/notification_badge_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/theme_provider.dart';
import '../area/area_form_screen.dart';
import '../contract/contract_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _hostId;
  String _fullName = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final hostId = await auth.getUserId();
    final fullName = auth.user?.fullName.trim().isNotEmpty == true
        ? auth.user!.fullName.trim()
        : (await _readCachedFullName()).trim();

    if (!mounted) return;
    setState(() {
      _hostId = hostId;
      _fullName = fullName;
    });

    if (hostId == null) return;

    await Future.wait([
      context.read<ReportProvider>().fetchDashboard(hostId),
      context.read<NotificationBadgeProvider>().refreshHost(hostId),
    ]);
  }

  Future<String> _readCachedFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.fullName) ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final reportProvider = context.watch<ReportProvider>();
    final unreadCount = context
        .watch<NotificationBadgeProvider>()
        .hostUnreadCount;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.gradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
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
                          isDark
                              ? Icons.light_mode_outlined
                              : Icons.dark_mode_outlined,
                          color: subtext,
                          size: 22,
                        ),
                        onPressed: () =>
                            context.read<ThemeProvider>().toggleTheme(),
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
                          final badgeProvider = context
                              .read<NotificationBadgeProvider>();
                          await context.push('/host/notifications');
                          if (!mounted || _hostId == null) return;
                          await badgeProvider.refreshHost(_hostId!);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.person_outline_rounded,
                          color: subtext,
                          size: 22,
                        ),
                        onPressed: () => ProfileBottomSheet.show(context),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
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
                        'Tổng quan hệ thống',
                        style: AppTextStyles.h1.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ),
              if (reportProvider.loading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppLoading(),
                )
              else if (reportProvider.error != null)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmpty(
                    message: reportProvider.error!,
                    icon: Icons.wifi_off_rounded,
                    actionLabel: 'Thử lại',
                    onAction: _load,
                  ),
                )
              else if (reportProvider.report == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: AppEmpty(
                    message: 'Không có dữ liệu tổng quan để hiển thị.',
                  ),
                )
              else
                SliverToBoxAdapter(
                  child: _buildBody(
                    context,
                    reportProvider.report!,
                    isDark,
                    fg,
                    subtext,
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ReportModel report,
    bool isDark,
    Color fg,
    Color subtext,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 8, child: _RevenueCard(report: report)),
              const SizedBox(width: 12),
              const Expanded(
                flex: 5,
                child: DashboardClockCard(compact: true),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Tình trạng phòng', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tổng phòng',
                  value: '${report.totalRooms}',
                  icon: Icons.meeting_room_outlined,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Đang thuê',
                  value: '${report.rentedRooms}',
                  icon: Icons.people_outline_rounded,
                  color: AppColors.roomRented,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Còn trống',
                  value: '${report.availableRooms}',
                  icon: Icons.door_front_door_outlined,
                  color: AppColors.roomAvailable,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Bảo trì',
                  value: '${report.maintenanceRooms}',
                  icon: Icons.build_outlined,
                  color: AppColors.roomMaintenance,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Cần xử lý', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AlertCard(
                  label: 'Hóa đơn quá hạn',
                  count: report.overdueCount,
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.invoiceOverdue,
                  onTap: () => context.push('/host/invoices'),
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AlertCard(
                  label: 'Khiếu nại mở',
                  count: report.openIssueCount,
                  icon: Icons.report_outlined,
                  color: AppColors.warning,
                  onTap: () => context.push('/host/issues'),
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _OccupancyBar(rate: report.occupancyRate, isDark: isDark),
          const SizedBox(height: 20),
          Text('Tạo nhanh', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 12),
          _CreateQuickActions(onComplete: _load),
          const SizedBox(height: 20),
          Text('Truy cập nhanh', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 12),
          const _QuickActions(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  final ReportModel report;

  const _RevenueCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final diff = report.totalRevenue - report.previousRevenue;
    final isUp = diff >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.account_balance_wallet_outlined,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Doanh thu tháng này',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
              const Spacer(),
              SectionBadge(
                label: isUp ? '▲ Tăng' : '▼ Giảm',
                color: isUp ? Colors.greenAccent : Colors.redAccent,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            CurrencyUtils.format(report.totalRevenue),
            style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28),
          ),
          const SizedBox(height: 8),
          Text(
            'Tháng trước: ${CurrencyUtils.format(report.previousRevenue)}',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value, style: AppTextStyles.h2.copyWith(color: fg)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall.copyWith(color: subtext)),
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
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
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
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: subtext),
        ],
      ),
    );
  }
}

class _OccupancyBar extends StatelessWidget {
  final double rate;
  final bool isDark;

  const _OccupancyBar({required this.rate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Tỷ lệ lấp đầy',
                style: AppTextStyles.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: AppTextStyles.h3.copyWith(color: AppColors.accent),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: rate / 100,
              minHeight: 8,
              backgroundColor: border,
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rate >= 80
                ? 'Tốt, hầu hết phòng đã có người thuê.'
                : rate >= 50
                ? 'Mức trung bình, vẫn còn nhiều phòng trống.'
                : 'Tỷ lệ lấp đầy thấp, nên đẩy mạnh cho thuê.',
            style: AppTextStyles.caption.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _actions = [
    _Action(Icons.meeting_room_outlined, 'Phòng trọ', '/host/rooms'),
    _Action(Icons.people_outline_rounded, 'Người thuê', '/host/tenants'),
    _Action(Icons.description_outlined, 'Hợp đồng', '/host/contracts'),
    _Action(Icons.receipt_long_outlined, 'Hóa đơn', '/host/invoices'),
    _Action(Icons.location_city_outlined, 'Khu trọ', '/host/areas'),
    _Action(Icons.savings_outlined, 'Đặt cọc', '/host/deposits'),
    _Action(Icons.notifications_outlined, 'Thông báo', '/host/notifications'),
    _Action(
      Icons.campaign_outlined,
      'Gửi thông báo',
      '/host/notifications/send',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 112,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, index) {
        final action = _actions[index];
        return AppCard(
          onTap: () => context.push(action.route),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(action.icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                action.label,
                style: AppTextStyles.caption.copyWith(color: fg),
                textAlign: TextAlign.center,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CreateQuickActions extends StatelessWidget {
  final Future<void> Function()? onComplete;

  const _CreateQuickActions({this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CreateActionCard(
            icon: Icons.location_city_outlined,
            title: 'Tạo khu trọ mới',
            subtitle: 'Khởi tạo khu trước khi thêm phòng.',
            onTap: () async {
              await AppPopupWindow.show(context, child: const AreaFormScreen());
              if (!context.mounted) return;
              await onComplete?.call();
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CreateActionCard(
            icon: Icons.note_add_outlined,
            title: 'Tạo hợp đồng mới',
            subtitle: 'Gán phòng và người thuê nhanh hơn.',
            onTap: () async {
              await AppPopupWindow.show(
                context,
                child: const ContractFormScreen(),
              );
              if (!context.mounted) return;
              await onComplete?.call();
            },
          ),
        ),
      ],
    );
  }
}

class _CreateActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _CreateActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      onTap: onTap,
      featured: true,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.accent, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTextStyles.body.copyWith(
              color: fg,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: AppTextStyles.caption.copyWith(color: subtext)),
        ],
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final String route;

  const _Action(this.icon, this.label, this.route);
}
