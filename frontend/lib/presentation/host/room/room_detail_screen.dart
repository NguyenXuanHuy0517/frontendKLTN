import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../core/utils/currency_utils.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/room_provider.dart';

class RoomDetailScreen extends StatefulWidget {
  final int roomId;
  const RoomDetailScreen({super.key, required this.roomId});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().fetchRoomDetail(widget.roomId);
    });
  }

  Future<void> _changeStatus(String newStatus) async {
    final confirm = await ConfirmDialog.show(
      context,
      title: 'Đổi trạng thái phòng',
      message: 'Xác nhận chuyển phòng sang trạng thái mới?',
    );
    if (!confirm || !mounted) return;

    final hostId = await context.read<AuthProvider>().getUserId();
    if (!mounted) return;

    final ok = await context.read<RoomProvider>().updateStatus(
      widget.roomId,
      newStatus,
      null,
      hostId!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Cập nhật thành công' : 'Cập nhật thất bại'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
    final room = context.watch<RoomProvider>().selected;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: fg, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          room != null ? 'Phòng ${room.roomCode}' : 'Chi tiết phòng',
          style: AppTextStyles.h3.copyWith(color: fg),
        ),
        actions: [
          if (room != null)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: AppColors.accent),
              onPressed: () =>
                  context.push('/host/rooms/${widget.roomId}/edit'),
            ),
        ],
      ),
      body: room == null
          ? const AppLoading()
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status banner ──────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _statusColor(room.status).withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _statusColor(room.status).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color:
                      _statusColor(room.status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.meeting_room_outlined,
                      color: _statusColor(room.status),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Phòng ${room.roomCode}',
                          style: AppTextStyles.h3.copyWith(color: fg),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          room.areaName,
                          style: AppTextStyles.bodySmall
                              .copyWith(color: subtext),
                        ),
                        const SizedBox(height: 8),
                        StatusBadge(status: room.status),
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
                    label: 'Giá thuê',
                    value: CurrencyUtils.format(room.basePrice),
                    valueColor: AppColors.accent,
                    isDark: isDark,
                  ),
                  Divider(color: border, height: 24),
                  _InfoRow(
                    label: 'Giá điện',
                    value:
                    '${CurrencyUtils.format(room.elecPrice)}/kWh',
                    isDark: isDark,
                  ),
                  Divider(color: border, height: 24),
                  _InfoRow(
                    label: 'Giá nước',
                    value:
                    '${CurrencyUtils.format(room.waterPrice)}/m³',
                    isDark: isDark,
                  ),
                  if (room.areaSize != null) ...[
                    Divider(color: border, height: 24),
                    _InfoRow(
                      label: 'Diện tích',
                      value: '${room.areaSize} m²',
                      isDark: isDark,
                    ),
                  ],
                  if (room.floor != null) ...[
                    Divider(color: border, height: 24),
                    _InfoRow(
                      label: 'Tầng',
                      value: '${room.floor}',
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
            ),

            // ── Tenant info ────────────────────────
            if (room.currentTenantName != null) ...[
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
                        Icons.person_outline_rounded,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Người đang thuê',
                            style: AppTextStyles.caption
                                .copyWith(color: subtext),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            room.currentTenantName!,
                            style: AppTextStyles.body
                                .copyWith(color: fg,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    if (room.currentContractId != null)
                      TextButton(
                        onPressed: () => context.push(
                          '/host/contracts/${room.currentContractId}',
                        ),
                        child: const Text('Xem HĐ'),
                      ),
                  ],
                ),
              ),
            ],

            // ── Description ────────────────────────
            if (room.description != null &&
                room.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mô tả',
                      style: AppTextStyles.body.copyWith(
                          color: fg, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      room.description!,
                      style: AppTextStyles.bodySmall
                          .copyWith(color: subtext),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // ── Status actions ─────────────────────
            if (room.status != 'RENTED') ...[
              Text(
                'Thay đổi trạng thái',
                style: AppTextStyles.h3.copyWith(color: fg),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (room.status != 'AVAILABLE')
                    _StatusBtn(
                      label: 'Còn trống',
                      color: AppColors.roomAvailable,
                      onTap: () => _changeStatus('AVAILABLE'),
                    ),
                  if (room.status != 'MAINTENANCE')
                    _StatusBtn(
                      label: 'Bảo trì',
                      color: AppColors.roomMaintenance,
                      onTap: () => _changeStatus('MAINTENANCE'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return AppColors.roomAvailable;
      case 'RENTED':
        return AppColors.roomRented;
      case 'DEPOSITED':
        return AppColors.roomDeposited;
      case 'MAINTENANCE':
        return AppColors.roomMaintenance;
      default:
        return AppColors.accent;
    }
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
        Text(label,
            style: AppTextStyles.body.copyWith(color: subtext)),
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

class _StatusBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatusBtn({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}