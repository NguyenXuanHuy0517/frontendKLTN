import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class PaymentStatusChip extends StatelessWidget {
  final String? status;

  const PaymentStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final normalized = (status ?? '').trim().toUpperCase();
    if (normalized.isEmpty) {
      return const SizedBox.shrink();
    }

    final config = switch (normalized) {
      'PENDING_REVIEW' => _ChipConfig(
        color: AppColors.warning,
        label: 'Chờ xác nhận chuyển khoản',
      ),
      'APPROVED' => _ChipConfig(
        color: AppColors.success,
        label: 'Đã duyệt chuyển khoản',
      ),
      _ => _ChipConfig(
        color: AppColors.info,
        label: normalized,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: config.color.withValues(alpha: 0.28)),
      ),
      child: Text(
        config.label,
        style: AppTextStyles.caption.copyWith(
          color: config.color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ChipConfig {
  final Color color;
  final String label;

  const _ChipConfig({required this.color, required this.label});
}
