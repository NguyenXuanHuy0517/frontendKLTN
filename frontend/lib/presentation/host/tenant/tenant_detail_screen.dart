import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../providers/tenant_provider.dart';

class TenantDetailScreen extends StatefulWidget {
  final int tenantId;
  const TenantDetailScreen({super.key, required this.tenantId});

  @override
  State<TenantDetailScreen> createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TenantProvider>().fetchTenantDetail(widget.tenantId);
    });
  }

  Future<void> _toggleActive() async {
    final tenant = context.read<TenantProvider>().selected;
    if (tenant == null) return;

    final confirm = await ConfirmDialog.show(
      context,
      title: tenant.active ? 'Khoá tài khoản' : 'Mở khoá tài khoản',
      message: tenant.active
          ? 'Người thuê sẽ không thể đăng nhập. Tiếp tục?'
          : 'Mở khoá để người thuê đăng nhập lại. Tiếp tục?',
      destructive: tenant.active,
    );
    if (!confirm || !mounted) return;

    final ok = await context.read<TenantProvider>().toggleActive(
      widget.tenantId,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cập nhật thành công' : 'Cập nhật thất bại'),
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
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final border = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final tenant = context.watch<TenantProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          tenant?.fullName ?? 'Chi tiết người thuê',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
      ),
      body: tenant == null
          ? const AppLoading()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Avatar banner ──────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.accent.withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: tenant.active
                                ? AppColors.accent.withOpacity(0.15)
                                : AppColors.darkSubtext.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: Text(
                              tenant.fullName.isNotEmpty
                                  ? tenant.fullName[0].toUpperCase()
                                  : '?',
                              style: AppTextStyles.h1.copyWith(
                                color: tenant.active
                                    ? AppColors.accent
                                    : AppColors.darkSubtext,
                                fontSize: 28,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.fullName,
                                style: AppTextStyles.h3.copyWith(color: fg),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tenant.email,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: subtext,
                                ),
                              ),
                              const SizedBox(height: 8),
                              StatusBadge(
                                status: tenant.active ? 'ACTIVE' : 'EXPIRED',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Info card ──────────────────────────
                  AppCard(
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Số điện thoại',
                          value: tenant.phoneNumber,
                          icon: Icons.phone_outlined,
                          isDark: isDark,
                        ),
                        Divider(color: border, height: 24),
                        _InfoRow(
                          label: 'Email',
                          value: tenant.email,
                          icon: Icons.mail_outline_rounded,
                          isDark: isDark,
                        ),
                        if (tenant.idCardNumber != null) ...[
                          Divider(color: border, height: 24),
                          _InfoRow(
                            label: 'CCCD / CMND',
                            value: tenant.idCardNumber!,
                            icon: Icons.badge_outlined,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ── Current room ───────────────────────
                  if (tenant.currentRoomCode != null) ...[
                    const SizedBox(height: 16),
                    AppCard(
                      featured: true,
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
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
                                  'Đang thuê',
                                  style: AppTextStyles.caption.copyWith(
                                    color: subtext,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Phòng ${tenant.currentRoomCode}',
                                  style: AppTextStyles.body.copyWith(
                                    color: fg,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (tenant.contractStatus != null)
                            StatusBadge(status: tenant.contractStatus!),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Actions ────────────────────────────
                  Text('Thao tác', style: AppTextStyles.h3.copyWith(color: fg)),
                  const SizedBox(height: 12),

                  // Toggle active
                  AppCard(
                    onTap: _toggleActive,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tenant.active
                                ? AppColors.error.withOpacity(0.1)
                                : AppColors.success.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            tenant.active
                                ? Icons.lock_outline_rounded
                                : Icons.lock_open_rounded,
                            color: tenant.active
                                ? AppColors.error
                                : AppColors.success,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tenant.active
                                    ? 'Khoá tài khoản'
                                    : 'Mở khoá tài khoản',
                                style: AppTextStyles.body.copyWith(
                                  color: tenant.active
                                      ? AppColors.error
                                      : AppColors.success,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                tenant.active
                                    ? 'Ngăn người thuê đăng nhập'
                                    : 'Cho phép người thuê đăng nhập lại',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: subtext,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: subtext,
                          size: 20,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Row(
      children: [
        Icon(icon, size: 18, color: subtext),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption.copyWith(color: subtext),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTextStyles.body.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
