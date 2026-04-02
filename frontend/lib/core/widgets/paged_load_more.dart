import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'app_button.dart';

class PagedLoadMore extends StatelessWidget {
  final bool loading;
  final bool hasNext;
  final VoidCallback onPressed;

  const PagedLoadMore({
    super.key,
    required this.loading,
    required this.hasNext,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    if (!loading && !hasNext) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              )
            : AppButton(
                label: 'Tải thêm',
                fullWidth: false,
                height: 42,
                variant: AppButtonVariant.outlined,
                onPressed: onPressed,
              ),
      ),
    );
  }
}
