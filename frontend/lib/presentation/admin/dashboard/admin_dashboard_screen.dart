import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/admin_alert_model.dart';
import '../../../data/models/admin_dashboard_model.dart';
import '../../../providers/admin_dashboard_provider.dart';
import '../../../providers/admin_revenue_provider.dart';
import '../widgets/admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    await Future.wait([
      context.read<AdminDashboardProvider>().fetchDashboard(),
      context.read<AdminRevenueProvider>().fetchRevenue('month'),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final dashboardProvider = context.watch<AdminDashboardProvider>();
    final revenueProvider = context.watch<AdminRevenueProvider>();
    final dashboard = dashboardProvider.dashboard;
    final revenue = revenueProvider.revenue;
    final loading =
        dashboardProvider.loading ||
        (revenueProvider.loading && revenue == null);
    final error = dashboardProvider.error ?? revenueProvider.error;

    return AdminShell(
      currentIndex: 0,
      title: 'Admin Dashboard',
      subtitle: 'Tong quan he thong, canh bao va xu huong doanh thu',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tai lai',
        ),
      ],
      child: loading && dashboard == null
          ? const AppLoading()
          : error != null && dashboard == null
          ? AppEmpty(
              message: error,
              icon: Icons.wifi_off_rounded,
              actionLabel: 'Thu lai',
              onAction: _load,
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  if (dashboard != null) ...[
                    _DashboardStatGrid(dashboard: dashboard),
                    const SizedBox(height: 20),
                    _QuickActionRow(
                      onHosts: () => context.go('/admin/hosts'),
                      onRooms: () => context.go('/admin/rooms'),
                      onRevenue: () => context.go('/admin/revenue'),
                    ),
                    const SizedBox(height: 20),
                    _AlertPanel(alerts: dashboard.alerts),
                    const SizedBox(height: 20),
                  ],
                  if (revenue != null)
                    _RevenueTrendPanel(
                      entries: revenue.revenueByPeriod.entries.toList(),
                    ),
                ],
              ),
            ),
    );
  }
}

class _DashboardStatGrid extends StatelessWidget {
  final AdminDashboardModel dashboard;

  const _DashboardStatGrid({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatCardData(
        'Tong users',
        '${dashboard.totalUsers}',
        Icons.groups_2_outlined,
        AppColors.accent,
      ),
      _StatCardData(
        'Hosts',
        '${dashboard.totalHosts}',
        Icons.apartment_outlined,
        AppColors.info,
      ),
      _StatCardData(
        'Tenants',
        '${dashboard.totalTenants}',
        Icons.badge_outlined,
        AppColors.success,
      ),
      _StatCardData(
        'Tong rooms',
        '${dashboard.totalRooms}',
        Icons.meeting_room_outlined,
        AppColors.accent,
      ),
      _StatCardData(
        'Tỷ lệ lấp đầy',
        '${dashboard.occupancyRate.toStringAsFixed(0)}%',
        Icons.pie_chart_outline_rounded,
        AppColors.info,
      ),
      _StatCardData(
        'Hợp đồng đang hoạt động',
        '${dashboard.activeContracts}',
        Icons.description_outlined,
        AppColors.success,
      ),
      _StatCardData(
        'Hóa đơn quá hạn',
        '${dashboard.overdueInvoices}',
        Icons.warning_amber_rounded,
        AppColors.error,
      ),
      _StatCardData(
        'Doanh thu tháng này',
        CurrencyUtils.formatCompact(dashboard.thisMonthRevenue),
        Icons.savings_outlined,
        AppColors.success,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1200
            ? 4
            : width >= 760
            ? 2
            : 1;
        final itemWidth = (width - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (card) => SizedBox(
                  width: itemWidth,
                  child: _StatCard(card: card),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCardData {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _StatCardData(this.label, this.value, this.icon, this.accent);
}

class _StatCard extends StatelessWidget {
  final _StatCardData card;

  const _StatCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      featured: card.accent == AppColors.error,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: card.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(card.icon, color: card.accent),
          ),
          const SizedBox(height: 16),
          Text(card.label, style: AppTextStyles.body2.copyWith(color: subtext)),
          const SizedBox(height: 6),
          Text(card.value, style: AppTextStyles.h2.copyWith(color: fg)),
        ],
      ),
    );
  }
}

class _QuickActionRow extends StatelessWidget {
  final VoidCallback onHosts;
  final VoidCallback onRooms;
  final VoidCallback onRevenue;

  const _QuickActionRow({
    required this.onHosts,
    required this.onRooms,
    required this.onRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionCardData(
        label: 'Host control',
        description: 'Xem va khoa/mo host',
        icon: Icons.apartment_rounded,
        onTap: onHosts,
      ),
      _QuickActionCardData(
        label: 'Room audit',
        description: 'Ra soat phong va hoa don thieu',
        icon: Icons.rule_folder_outlined,
        onTap: onRooms,
      ),
      _QuickActionCardData(
        label: 'Revenue',
        description: 'Phan tich doanh thu theo ky',
        icon: Icons.show_chart_rounded,
        onTap: onRevenue,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100 ? 3 : 1;
        final itemWidth = (width - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: actions
              .map(
                (action) => SizedBox(
                  width: columns == 1 ? width : itemWidth,
                  child: AppCard(
                    onTap: action.onTap,
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(action.icon, color: AppColors.accent),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(action.label, style: AppTextStyles.h3),
                              const SizedBox(height: 4),
                              Text(
                                action.description,
                                style: AppTextStyles.body2.copyWith(
                                  color:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? AppColors.darkSubtext
                                      : AppColors.lightSubtext,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _QuickActionCardData {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickActionCardData({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
  });
}

class _AlertPanel extends StatelessWidget {
  final List<AdminAlertModel> alerts;

  const _AlertPanel({required this.alerts});

  Color _severityColor(String severity) {
    switch (severity) {
      case 'error':
      case 'high':
        return AppColors.error;
      case 'warning':
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return AppCard(
      featured: alerts.isNotEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quick alerts', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 6),
          Text(
            'Cac canh bao backend tra ve de admin uu tien xu ly',
            style: AppTextStyles.body2.copyWith(color: subtext),
          ),
          const SizedBox(height: 16),
          if (alerts.isEmpty)
            Text(
              'Chua co canh bao nao.',
              style: AppTextStyles.body.copyWith(color: subtext),
            )
          else
            ...alerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _severityColor(alert.severity).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _severityColor(
                      alert.severity,
                    ).withValues(alpha: 0.22),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.priority_high_rounded,
                      color: _severityColor(alert.severity),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(alert.title, style: AppTextStyles.body),
                          if (alert.description.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              alert.description,
                              style: AppTextStyles.body2.copyWith(
                                color: subtext,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (alert.count > 0)
                      Text(
                        '${alert.count}',
                        style: AppTextStyles.h3.copyWith(
                          color: _severityColor(alert.severity),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueTrendPanel extends StatelessWidget {
  final List<MapEntry<String, double>> entries;

  const _RevenueTrendPanel({required this.entries});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final maxValue = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Revenue trend', style: AppTextStyles.h3.copyWith(color: fg)),
          const SizedBox(height: 6),
          Text(
            'Doanh thu gan day theo du lieu tu backend',
            style: AppTextStyles.body2.copyWith(color: subtext),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Text(
              'Chua co du lieu doanh thu.',
              style: AppTextStyles.body.copyWith(color: subtext),
            )
          else
            ...entries
                .take(6)
                .map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 94,
                          child: Text(entry.key, style: AppTextStyles.caption),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: LinearProgressIndicator(
                              value: maxValue == 0 ? 0 : entry.value / maxValue,
                              minHeight: 10,
                              backgroundColor: AppColors.accent.withValues(
                                alpha: 0.12,
                              ),
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 96,
                          child: Text(
                            CurrencyUtils.formatCompact(entry.value),
                            textAlign: TextAlign.right,
                            style: AppTextStyles.bodySmall.copyWith(color: fg),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}
