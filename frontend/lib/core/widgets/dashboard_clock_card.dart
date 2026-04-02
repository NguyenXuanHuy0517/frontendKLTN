import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class DashboardClockCard extends StatefulWidget {
  final bool compact;

  const DashboardClockCard({super.key, this.compact = false});

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
    final title = widget.compact ? 'Thoi gian' : 'Thoi gian hien tai';
    final padding = widget.compact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final iconSize = widget.compact ? 14.0 : 16.0;
    final timeStyle = widget.compact ? AppTextStyles.h3 : AppTextStyles.h2;
    final timeSpacing = widget.compact ? 6.0 : 8.0;
    final dateSpacing = widget.compact ? 1.0 : 2.0;

    return Container(
      constraints: BoxConstraints(minWidth: widget.compact ? 0 : 210),
      padding: padding,
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
              Icon(
                Icons.schedule_rounded,
                color: AppColors.accent,
                size: iconSize,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: AppTextStyles.caption.copyWith(
                  color: subtext,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: timeSpacing),
          Text(_timeLabel, style: timeStyle.copyWith(color: fg)),
          SizedBox(height: dateSpacing),
          Text(
            _dateLabel,
            style: AppTextStyles.caption.copyWith(color: subtext),
          ),
        ],
      ),
    );
  }
}
