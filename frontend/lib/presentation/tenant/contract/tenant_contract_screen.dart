import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contract_provider.dart';

class TenantContractScreen extends StatefulWidget {
  const TenantContractScreen({super.key});
  @override
  State<TenantContractScreen> createState() => _TenantContractScreenState();
}

class _TenantContractScreenState extends State<TenantContractScreen> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = await context.read<AuthProvider>().getUserId();
    if (userId != null && mounted) {
      context.read<ContractProvider>().fetchContractsByTenant(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark   = Theme.of(context).brightness == Brightness.dark;
    final bg       = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg       = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext  = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border   = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final provider = context.watch<ContractProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Hợp đồng của tôi',
            style: AppTextStyles.h3.copyWith(color: fg)),
      ),
      body: provider.loading
          ? const AppLoading()
          : provider.contracts.isEmpty
          ? const AppEmpty(
        message: 'Chưa có hợp đồng nào',
        icon: Icons.description_outlined,
      )
          : RefreshIndicator(
        color: AppColors.accent,
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.all(24),
          itemCount: provider.contracts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final c = provider.contracts[i];
            final endDate    = DateTime.tryParse(c.endDate);
            final daysLeft   = endDate != null
                ? endDate.difference(DateTime.now()).inDays : null;
            final expireSoon = daysLeft != null && daysLeft <= 30;

            return AppCard(
              featured: c.status == 'ACTIVE',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.description_outlined,
                          color: AppColors.accent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.contractCode,
                            style: AppTextStyles.body.copyWith(
                                color: fg,
                                fontWeight: FontWeight.w600)),
                        Text('Phòng ${c.roomCode} — ${c.areaName}',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: subtext),
                            overflow: TextOverflow.ellipsis),
                      ],
                    )),
                    StatusBadge(status: c.status),
                  ]),
                  Divider(color: border, height: 20),
                  _InfoRow('Giá thuê',
                      CurrencyUtils.format(c.actualRentPrice),
                      AppColors.accent),
                  const SizedBox(height: 6),
                  _InfoRow('Bắt đầu',
                      AppDateUtils.formatDate(c.startDate), fg),
                  const SizedBox(height: 6),
                  _InfoRow('Kết thúc',
                      AppDateUtils.formatDate(c.endDate),
                      expireSoon ? AppColors.warning : fg),
                  if (expireSoon && daysLeft! >= 0) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 16, color: AppColors.warning),
                        const SizedBox(width: 8),
                        Text('Còn $daysLeft ngày hết hạn',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600)),
                      ]),
                    ),
                  ],
                  if (c.serviceNames.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6, runSpacing: 4,
                      children: c.serviceNames.map((s) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(s,
                            style: AppTextStyles.caption
                                .copyWith(color: AppColors.accent)),
                      )).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label, value;
  final Color valueColor;
  const _InfoRow(this.label, this.value, this.valueColor);
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodySmall.copyWith(color: subtext)),
      Text(value, style: AppTextStyles.bodySmall.copyWith(
          color: valueColor, fontWeight: FontWeight.w600)),
    ]);
  }
}