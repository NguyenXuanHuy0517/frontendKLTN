import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/host_bottom_nav.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../core/utils/date_utils.dart';
import '../../../data/models/deposit_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/deposit_provider.dart';

class DepositListScreen extends StatefulWidget {
  const DepositListScreen({super.key});

  @override
  State<DepositListScreen> createState() => _DepositListScreenState();
}

class _DepositListScreenState extends State<DepositListScreen> {
  int? _hostId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    _hostId = await context.read<AuthProvider>().getUserId();
    if (_hostId != null && mounted) {
      context.read<DepositProvider>().fetchDeposits(_hostId!);
    }
  }

  Future<void> _confirmDeposit(int depositId) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Xác nhận đặt cọc',
      message: 'Xác nhận đã nhận tiền cọc từ người thuê?',
    );
    if (!confirm || !mounted) return;

    final ok = await context.read<DepositProvider>().confirmDeposit(
      depositId,
      _hostId!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Xác nhận thành công' : 'Xác nhận thất bại'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _refundDeposit(int depositId) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Hoàn cọc',
      message: 'Xác nhận hoàn tiền cọc cho người thuê? Phòng sẽ được mở lại.',
      destructive: true,
    );
    if (!confirm || !mounted) return;

    final ok = await context.read<DepositProvider>().refundDeposit(depositId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Hoàn cọc thành công' : 'Hoàn cọc thất bại'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBg : AppColors.lightBg;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final provider = context.watch<DepositProvider>();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text('Đặt cọc', style: AppTextStyles.h3.copyWith(color: fg)),
      ),
      body: provider.loading
          ? const AppLoading()
          : provider.deposits.isEmpty
          ? const AppEmpty(
              message: 'Chưa có đặt cọc nào',
              icon: Icons.savings_outlined,
            )
          : RefreshIndicator(
              color: AppColors.accent,
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: provider.deposits.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _DepositCard(
                  deposit: provider.deposits[i],
                  isDark: isDark,
                  onConfirm: () =>
                      _confirmDeposit(provider.deposits[i].depositId),
                  onRefund: () =>
                      _refundDeposit(provider.deposits[i].depositId),
                ),
              ),
            ),
      bottomNavigationBar: const HostBottomNav(currentIndex: 0),
    );
  }
}

class _DepositCard extends StatelessWidget {
  final DepositModel deposit;
  final bool isDark;
  final VoidCallback onConfirm;
  final VoidCallback onRefund;

  const _DepositCard({
    required this.deposit,
    required this.isDark,
    required this.onConfirm,
    required this.onRefund,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deposit.tenantName,
                      style: AppTextStyles.body.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Phòng ${deposit.roomCode}',
                      style: AppTextStyles.bodySmall.copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
              StatusBadge(status: deposit.status),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: border, height: 1),
          const SizedBox(height: 16),

          // Amount + Date
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số tiền cọc',
                      style: AppTextStyles.caption.copyWith(color: subtext),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyUtils.format(deposit.amount),
                      style: AppTextStyles.h3.copyWith(color: AppColors.accent),
                    ),
                  ],
                ),
              ),
              if (deposit.expectedCheckIn != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dự kiến vào',
                        style: AppTextStyles.caption.copyWith(color: subtext),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppDateUtils.formatDate(deposit.expectedCheckIn),
                        style: AppTextStyles.body.copyWith(color: fg),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          if (deposit.note != null && deposit.note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              deposit.note!,
              style: AppTextStyles.bodySmall.copyWith(color: subtext),
            ),
          ],

          // Actions
          if (deposit.status == 'PENDING' || deposit.status == 'CONFIRMED') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (deposit.status == 'PENDING')
                  Expanded(
                    child: _ActionBtn(
                      label: 'Xác nhận nhận cọc',
                      color: AppColors.success,
                      icon: Icons.check_rounded,
                      onTap: onConfirm,
                    ),
                  ),
                if (deposit.status == 'PENDING') const SizedBox(width: 8),
                Expanded(
                  child: _ActionBtn(
                    label: 'Hoàn cọc',
                    color: AppColors.error,
                    icon: Icons.undo_rounded,
                    onTap: onRefund,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
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
