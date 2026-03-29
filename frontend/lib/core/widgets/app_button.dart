import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum AppButtonVariant { gradient, filled, outlined, text }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool fullWidth;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.gradient,
    this.icon,
    this.loading = false,
    this.fullWidth = true,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget child = loading
        ? const SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: Colors.white,
      ),
    )
        : Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label, style: AppTextStyles.button),
      ],
    );

    Widget button;

    switch (variant) {
      case AppButtonVariant.gradient:
        button = Container(
          height: height,
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: AppColors.gradient,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: loading ? null : onPressed,
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: DefaultTextStyle(
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                  child: IconTheme(
                    data: const IconThemeData(color: Colors.white),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        );

      case AppButtonVariant.filled:
        button = SizedBox(
          height: height,
          width: fullWidth ? double.infinity : null,
          child: ElevatedButton(
            onPressed: loading ? null : onPressed,
            child: child,
          ),
        );

      case AppButtonVariant.outlined:
        button = SizedBox(
          height: height,
          width: fullWidth ? double.infinity : null,
          child: OutlinedButton(
            onPressed: loading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: const BorderSide(color: AppColors.accent),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: child,
          ),
        );

      case AppButtonVariant.text:
        button = TextButton(
          onPressed: loading ? null : onPressed,
          child: child,
        );
    }

    return button;
  }
}