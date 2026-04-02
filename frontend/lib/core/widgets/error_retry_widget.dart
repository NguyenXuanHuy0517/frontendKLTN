import 'package:flutter/material.dart';

import 'app_empty.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorRetryWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmpty(
      message: message,
      icon: Icons.wifi_off_rounded,
      actionLabel: 'Thử lại',
      onAction: onRetry,
    );
  }
}
