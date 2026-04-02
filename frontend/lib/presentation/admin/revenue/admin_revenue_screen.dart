import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../data/models/admin_revenue_model.dart';
import '../../../providers/admin_revenue_provider.dart';
import '../widgets/admin_shell.dart';

class AdminRevenueScreen extends StatefulWidget {
  const AdminRevenueScreen({super.key});

  @override
  State<AdminRevenueScreen> createState() => _AdminRevenueScreenState();
}

class _AdminRevenueScreenState extends State<AdminRevenueScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminRevenueProvider>().fetchRevenue();
  }

  Future<void> _changePeriod(String period) async {
    await context.read<AdminRevenueProvider>().fetchRevenue(period);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminRevenueProvider>();
    final revenue = provider.revenue;

    return AdminShell(
      currentIndex: 3,
      title: 'Revenue Analytics',
      subtitle: 'Doanh thu tong hop theo month, quarter va year',
      actions: [
        IconButton(
          onPressed: () => _changePeriod(provider.period),
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Tai lai',
        ),
      ],
      child: provider.loading && revenue == null
          ? const AppLoading()
          : provider.error != null && revenue == null
          ? AppEmpty(
              message: provider.error!,
              icon: Icons.show_chart_outlined,
              actionLabel: 'Thu lai',
              onAction: () => _changePeriod(provider.period),
            )
          : revenue == null
          ? const AppEmpty(message: 'Khong co du lieu doanh thu.')
          : RefreshIndicator(
              onRefresh: () => _changePeriod(provider.period),
              color: AppColors.accent,
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final option in const ['month', 'quarter', 'year'])
                        ChoiceChip(
                          label: Text(option.toUpperCase()),
                          selected: provider.period == option,
                          onSelected: (_) => _changePeriod(option),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _RevenueHeaderCards(revenue: revenue),
                  const SizedBox(height: 20),
                  _RevenueTrendCard(revenue: revenue),
                  const SizedBox(height: 20),
                  _TopHostsCard(revenue: revenue),
                ],
              ),
            ),
    );
  }
}

class _RevenueHeaderCards extends StatelessWidget {
  final AdminRevenueModel revenue;

  const _RevenueHeaderCards({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final cards = [
      (
        'Total revenue',
        CurrencyUtils.format(revenue.totalRevenue),
        AppColors.accent,
      ),
      (
        'Average / period',
        CurrencyUtils.formatCompact(revenue.averageRevenue),
        AppColors.success,
      ),
      ('Periods', '${revenue.revenueByPeriod.length}', AppColors.info),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 980 ? 3 : 1;
        final itemWidth = (width - (columns - 1) * 16) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: cards
              .map(
                (item) => SizedBox(
                  width: columns == 1 ? width : itemWidth,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.$1, style: AppTextStyles.caption),
                        const SizedBox(height: 8),
                        Text(
                          item.$2,
                          style: AppTextStyles.h2.copyWith(color: item.$3),
                        ),
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

class _RevenueTrendCard extends StatelessWidget {
  final AdminRevenueModel revenue;

  const _RevenueTrendCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final entries = revenue.revenueByPeriod.entries.toList();
    final maxValue = entries.isEmpty
        ? 1.0
        : entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final subtext = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Trend by period', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Bieu do don gian khong dung package chart bo sung',
            style: AppTextStyles.body2.copyWith(color: subtext),
          ),
          const SizedBox(height: 18),
          if (entries.isEmpty)
            Text(
              'Chua co du lieu theo ky.',
              style: AppTextStyles.body.copyWith(color: subtext),
            )
          else
            ...entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(entry.key, style: AppTextStyles.caption),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          minHeight: 12,
                          value: maxValue == 0 ? 0 : entry.value / maxValue,
                          backgroundColor: AppColors.accent.withValues(
                            alpha: 0.12,
                          ),
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: Text(
                        CurrencyUtils.formatCompact(entry.value),
                        textAlign: TextAlign.right,
                        style: AppTextStyles.body2,
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

class _TopHostsCard extends StatelessWidget {
  final AdminRevenueModel revenue;

  const _TopHostsCard({required this.revenue});

  @override
  Widget build(BuildContext context) {
    final subtext = Theme.of(context).brightness == Brightness.dark
        ? AppColors.darkSubtext
        : AppColors.lightSubtext;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top hosts', style: AppTextStyles.h3),
          const SizedBox(height: 6),
          Text(
            'Neu backend chua tra topHosts, khu vuc nay se hien trang thai trong.',
            style: AppTextStyles.body2.copyWith(color: subtext),
          ),
          const SizedBox(height: 16),
          if (revenue.topHosts.isEmpty)
            Text(
              'Backend chua cung cap topHosts.',
              style: AppTextStyles.body.copyWith(color: subtext),
            )
          else
            ...revenue.topHosts.map(
              (host) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(host.hostName, style: AppTextStyles.body),
                    ),
                    Text(
                      CurrencyUtils.formatCompact(host.revenue),
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
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
