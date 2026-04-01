import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/contract_provider.dart';

class ContractDetailScreen extends StatefulWidget {
  final int contractId;

  const ContractDetailScreen({super.key, required this.contractId});

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContractProvider>().fetchContractDetail(widget.contractId);
    });
  }

  Future<void> _terminate() async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Chấm dứt hợp đồng',
      message:
          'Hợp đồng sẽ bị chấm dứt sớm và phòng sẽ được mở lại. Tiếp tục?',
      destructive: true,
      confirmLabel: 'Chấm dứt',
    );
    if (!confirm || !mounted) return;

    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    final ok = await context
        .read<ContractProvider>()
        .terminateContract(widget.contractId, hostId!);

    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Chấm dứt hợp đồng thành công'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final contract = context.watch<ContractProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          contract?.contractCode ?? 'Chi tiết hợp đồng',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (contract?.status == 'ACTIVE')
            IconButton(
              icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
              onPressed: _terminate,
            ),
        ],
      ),
      body: contract == null
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                contract.tenantName,
                                style: AppTextStyles.h3.copyWith(color: fg),
                              ),
                            ),
                            StatusBadge(status: contract.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Phòng ${contract.roomCode} • ${contract.areaName}',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subtext,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          contract.contractCode,
                          style: AppTextStyles.caption.copyWith(color: subtext),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Thông tin hợp đồng',
                    style: AppTextStyles.h3.copyWith(color: fg),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Giá thuê',
                          value: CurrencyUtils.format(contract.actualRentPrice),
                          valueColor: AppColors.accent,
                          isDark: isDark,
                        ),
                        Divider(color: border, height: 24),
                        _InfoRow(
                          label: 'Ngày bắt đầu',
                          value: AppDateUtils.formatDate(contract.startDate),
                          isDark: isDark,
                        ),
                        Divider(color: border, height: 24),
                        _InfoRow(
                          label: 'Ngày kết thúc',
                          value: AppDateUtils.formatDate(contract.endDate),
                          isDark: isDark,
                        ),
                        if (contract.elecPriceOverride != null) ...[
                          Divider(color: border, height: 24),
                          _InfoRow(
                            label: 'Giá điện riêng',
                            value:
                                '${CurrencyUtils.format(contract.elecPriceOverride!)}/kWh',
                            isDark: isDark,
                          ),
                        ],
                        if (contract.waterPriceOverride != null) ...[
                          Divider(color: border, height: 24),
                          _InfoRow(
                            label: 'Giá nước riêng',
                            value:
                                '${CurrencyUtils.format(contract.waterPriceOverride!)}/m³',
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (contract.contractServices.isNotEmpty ||
                      contract.serviceNames.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Dịch vụ đăng ký',
                      style: AppTextStyles.h3.copyWith(color: fg),
                    ),
                    const SizedBox(height: 12),
                    AppCard(
                      child: Column(
                        children: contract.contractServices.isNotEmpty
                            ? contract.contractServices
                                .map(
                                  (service) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            service.quantity > 1
                                                ? '${service.serviceName} x${service.quantity}'
                                                : service.serviceName,
                                            style: AppTextStyles.body.copyWith(
                                              color: fg,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${CurrencyUtils.format(service.displayPrice)}/${service.displayUnit}',
                                          style:
                                              AppTextStyles.bodySmall.copyWith(
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList()
                            : contract.serviceNames
                                .map(
                                  (serviceName) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.check_circle_outline,
                                          size: 16,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          serviceName,
                                          style: AppTextStyles.body.copyWith(
                                            color: fg,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),
                  ],
                  if (contract.status == 'ACTIVE') ...[
                    const SizedBox(height: 24),
                    _ActionBtn(
                      label: 'Gia hạn hợp đồng',
                      icon: Icons.update_rounded,
                      color: AppColors.accent,
                      onTap: () => _showExtendDialog(context),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  void _showExtendDialog(BuildContext context) {
    DateTime? newEndDate;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gia hạn hợp đồng'),
        content: StatefulBuilder(
          builder: (dialogContext, setDialogState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Chọn ngày kết thúc mới:'),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  newEndDate != null
                      ? AppDateUtils.formatDate(newEndDate!.toIso8601String())
                      : 'Chọn ngày',
                ),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime.now(),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365 * 3)),
                  );
                  if (picked != null) {
                    setDialogState(() => newEndDate = picked);
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              if (newEndDate == null) return;
              Navigator.pop(ctx);
              final ok = await context.read<ContractProvider>().extendContract(
                    widget.contractId,
                    newEndDate!.toIso8601String().split('T')[0],
                  );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    ok ? 'Gia hạn thành công' : 'Gia hạn thất bại',
                  ),
                  backgroundColor:
                      ok ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            },
            child: const Text('Gia hạn'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.body.copyWith(color: subtext)),
        Text(
          value,
          style: AppTextStyles.body.copyWith(
            color: valueColor ?? fg,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
