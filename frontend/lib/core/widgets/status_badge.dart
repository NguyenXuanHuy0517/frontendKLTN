import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _config(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
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

  _BadgeConfig _config(String value) {
    switch (value.toUpperCase()) {
      case 'AVAILABLE':
        return _BadgeConfig(AppColors.roomAvailable, 'Còn trống');
      case 'RENTED':
        return _BadgeConfig(AppColors.roomRented, 'Đang thuê');
      case 'DEPOSITED':
        return _BadgeConfig(AppColors.roomDeposited, 'Đã cọc');
      case 'MAINTENANCE':
        return _BadgeConfig(AppColors.roomMaintenance, 'Bảo trì');
      case 'ACTIVE':
        return _BadgeConfig(AppColors.success, 'Đang hiệu lực');
      case 'EXPIRED':
        return _BadgeConfig(AppColors.error, 'Hết hạn');
      case 'TERMINATED_EARLY':
        return _BadgeConfig(AppColors.error, 'Chấm dứt sớm');
      case 'PAID':
        return _BadgeConfig(AppColors.invoicePaid, 'Đã thanh toán');
      case 'UNPAID':
        return _BadgeConfig(AppColors.invoiceUnpaid, 'Chưa thanh toán');
      case 'OVERDUE':
        return _BadgeConfig(AppColors.invoiceOverdue, 'Quá hạn');
      case 'DRAFT':
        return _BadgeConfig(AppColors.invoiceDraft, 'Nháp');
      case 'OPEN':
        return _BadgeConfig(AppColors.error, 'Mới');
      case 'PROCESSING':
        return _BadgeConfig(AppColors.warning, 'Đang xử lý');
      case 'RESOLVED':
        return _BadgeConfig(AppColors.success, 'Đã giải quyết');
      case 'CLOSED':
        return _BadgeConfig(AppColors.invoiceDraft, 'Đã đóng');
      case 'PENDING':
        return _BadgeConfig(AppColors.warning, 'Chờ xác nhận');
      case 'CONFIRMED':
        return _BadgeConfig(AppColors.info, 'Đã xác nhận');
      case 'COMPLETED':
        return _BadgeConfig(AppColors.success, 'Hoàn thành');
      case 'REFUNDED':
        return _BadgeConfig(AppColors.invoiceDraft, 'Đã hoàn cọc');
      case 'FORFEITED':
        return _BadgeConfig(AppColors.error, 'Mất cọc');
      default:
        return _BadgeConfig(AppColors.invoiceDraft, value);
    }
  }
}

class _BadgeConfig {
  final Color color;
  final String label;

  const _BadgeConfig(this.color, this.label);
}
