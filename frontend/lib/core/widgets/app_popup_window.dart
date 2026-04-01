import 'dart:math' as math;

import 'package:flutter/material.dart';

class AppPopupWindow {
  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    double maxWidth = 960,
    double maxHeight = 840,
    bool barrierDismissible = true,
  }) {
    final media = MediaQuery.of(context);
    final useBottomSheet = media.size.width < 720;

    if (useBottomSheet) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.94,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: child,
          ),
        ),
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (_) {
        final width = math.min(maxWidth, media.size.width - 48);
        final height = math.min(maxHeight, media.size.height - 48);
        return Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          child: SizedBox(
            width: width,
            height: height,
            child: child,
          ),
        );
      },
    );
  }
}
