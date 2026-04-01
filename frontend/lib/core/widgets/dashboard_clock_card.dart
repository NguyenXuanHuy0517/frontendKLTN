import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DashboardClockCard extends StatefulWidget {
  const DashboardClockCard({super.key});

  @override
  State<DashboardClockCard> createState() => _DashboardClockCardState();
}

class _DashboardClockCardState extends State<DashboardClockCard> {
  static const _weekdays = [
    'Thu Hai',
    'Thu Ba',
    'Thu Tu',
    'Thu Nam',
    'Thu Sau',
    'Thu Bay',
    'Chu Nhat',
  ];

  late DateTime _now;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _timeLabel {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  String get _dateLabel {
    final weekday = _weekdays[_now.weekday - 1];
    final day = _now.day.toString().padLeft(2, '0');
    final month = _now.month.toString().padLeft(2, '0');
    return '$weekday, $day/$month/${_now.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final fg = isDark ? AppColors.darkFg : AppColors.lightFg;
    final subtext = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Container(
      constraints: const BoxConstraints(minWidth: 210),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                'Thoi gian hien tai',
                style: AppTextStyles.caption.copyWith(
                  color: subtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _timeLabel,
            style: AppTextStyles.h2.copyWith(color: fg),
          ),
          const SizedBox(height: 2),
          Text(
            _dateLabel,
            style: AppTextStyles.caption.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}
