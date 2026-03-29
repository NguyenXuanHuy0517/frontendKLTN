import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/gradient_text.dart';
import '../../../core/widgets/section_badge.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../data/models/report_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/report_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../core/utils/currency_utils.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int? _hostId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    _hostId = await auth.getUserId();
    if (_hostId != null) {
      if (!mounted) return;
      context.read<ReportProvider>().fetchDashboard(_hostId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final report = context.watch<ReportProvider>();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            if (_hostId != null) {
              await context.read<ReportProvider>().fetchDashboard(_hostId!);
            }
          },
          child: CustomScrollView(
            slivers: [
              // ── App Bar ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    children: [
                      // Logo
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
                      // Theme toggle
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
                      // Notification
                      IconButton(
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: subtext,
                          size: 22,
                        ),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),

              // ── Greeting ─────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Xin chào,',
                        style:
                        AppTextStyles.body.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tổng quan hệ thống',
                        style: AppTextStyles.h1.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────
              if (report.loading)
                const SliverFillRemaining(child: AppLoading())
              else if (report.error != null)
                SliverFillRemaining(
                  child: AppEmpty(
                    message: report.error!,
                    icon: Icons.wifi_off_rounded,
                    actionLabel: 'Thử lại',
                    onAction: _load,
                  ),
                )
              else if (report.report == null)
                  const SliverFillRemaining(
                    child: AppEmpty(message: 'Không có dữ liệu'),
                  )
                else ...[
                    SliverToBoxAdapter(
                      child: _buildBody(
                          context, report.report!, isDark, fg, subtext),
                    ),
                  ],
            ],
          ),
        ),
      ),

      // ── Bottom Nav ──────────────────────────────────────
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody(BuildContext context, ReportModel r, bool isDark,
      Color fg, Color subtext) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 28),

          // ── Revenue card ─────────────────────────────────
          _RevenueCard(report: r, isDark: isDark),

          const SizedBox(height: 20),

          // ── Room stats ───────────────────────────────────
          Text(
            'Tình trạng phòng',
            style: AppTextStyles.h3.copyWith(color: fg),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Tổng phòng',
                  value: '${r.totalRooms}',
                  icon: Icons.meeting_room_outlined,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Đang thuê',
                  value: '${r.rentedRooms}',
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
                  value: '${r.availableRooms}',
                  icon: Icons.door_front_door_outlined,
                  color: AppColors.roomAvailable,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Bảo trì',
                  value: '${r.maintenanceRooms}',
                  icon: Icons.build_outlined,
                  color: AppColors.roomMaintenance,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Alert cards ───────────────────────────────────
          Text(
            'Cần xử lý',
            style: AppTextStyles.h3.copyWith(color: fg),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _AlertCard(
                  label: 'Hóa đơn quá hạn',
                  count: r.overdueCount,
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
                  count: r.openIssueCount,
                  icon: Icons.report_outlined,
                  color: AppColors.warning,
                  onTap: () => context.push('/host/issues'),
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Occupancy bar ─────────────────────────────────
          _OccupancyBar(rate: r.occupancyRate, isDark: isDark),

          const SizedBox(height: 20),

          // ── Quick actions ─────────────────────────────────
          Text(
            'Truy cập nhanh',
            style: AppTextStyles.h3.copyWith(color: fg),
          ),
          const SizedBox(height: 12),
          _QuickActions(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// ── Revenue Card ────────────────────────────────────────────
class _RevenueCard extends StatelessWidget {
  final ReportModel report;
  final bool isDark;

  const _RevenueCard({required this.report, required this.isDark});

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
            color: AppColors.accent.withOpacity(0.3),
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
              const Icon(Icons.account_balance_wallet_outlined,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 8),
              Text(
                'Doanh thu tháng này',
                style: AppTextStyles.bodySmall
                    .copyWith(color: Colors.white70),
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
            style: AppTextStyles.h1.copyWith(
              color: Colors.white,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tháng trước: ${CurrencyUtils.format(report.previousRevenue)}',
            style:
            AppTextStyles.bodySmall.copyWith(color: Colors.white60),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ────────────────────────────────────────────────
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
    final subtext =
    isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.h2.copyWith(color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}

// ── Alert Card ───────────────────────────────────────────────
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
    final subtext =
    isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

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
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count',
                  style: AppTextStyles.h3.copyWith(color: fg),
                ),
                Text(
                  label,
                  style: AppTextStyles.caption
                      .copyWith(color: subtext),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: subtext,
          ),
        ],
      ),
    );
  }
}

// ── Occupancy Bar ────────────────────────────────────────────
class _OccupancyBar extends StatelessWidget {
  final double rate;
  final bool isDark;

  const _OccupancyBar({required this.rate, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext =
    isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border =
    isDark ? AppColors.darkBorder : AppColors.lightBorder;

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
                    color: fg, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '${rate.toStringAsFixed(1)}%',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.accent,
                ),
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
                ? 'Tốt — hầu hết phòng đã có người thuê'
                : rate >= 50
                ? 'Trung bình — còn nhiều phòng trống'
                : 'Thấp — cần tăng cường cho thuê',
            style: AppTextStyles.caption.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}

// ── Quick Actions ────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  final _actions = const [
    _Action(Icons.meeting_room_outlined, 'Phòng trọ', '/host/rooms'),
    _Action(Icons.people_outline_rounded, 'Người thuê', '/host/tenants'),
    _Action(Icons.description_outlined, 'Hợp đồng', '/host/contracts'),
    _Action(Icons.receipt_long_outlined, 'Hóa đơn', '/host/invoices'),
    _Action(Icons.location_city_outlined, 'Khu trọ', '/host/areas'),
    _Action(Icons.savings_outlined, 'Đặt cọc', '/host/deposits'),
  ];

  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtext =
    isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _actions.length,
      itemBuilder: (context, i) {
        final action = _actions[i];
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
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  action.icon,
                  color: AppColors.accent,
                  size: 22,
                ),
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

class _Action {
  final IconData icon;
  final String label;
  final String route;
  const _Action(this.icon, this.label, this.route);
}

// ── Bottom Navigation ────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  const _BottomNav({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkCard : AppColors.lightCard;
    final border =
    isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(top: BorderSide(color: border)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.accent,
        unselectedItemColor:
        isDark ? AppColors.darkSubtext : AppColors.lightSubtext,
        selectedLabelStyle: AppTextStyles.caption,
        unselectedLabelStyle: AppTextStyles.caption,
        onTap: (i) {
          switch (i) {
            case 0:
              context.go('/host/dashboard');
            case 1:
              context.go('/host/rooms');
            case 2:
              context.go('/host/invoices');
            case 3:
              context.go('/host/issues');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.meeting_room_outlined),
            activeIcon: Icon(Icons.meeting_room_rounded),
            label: 'Phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long_rounded),
            label: 'Hóa đơn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_outlined),
            activeIcon: Icon(Icons.report_rounded),
            label: 'Khiếu nại',
          ),
        ],
      ),
    );
  }
}