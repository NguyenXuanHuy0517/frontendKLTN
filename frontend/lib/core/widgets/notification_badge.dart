import 'package:flutter/material.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool showBadge;
  final double dotSize;
  final Color color;

  const NotificationBadge({
    super.key,
    required this.child,
    required this.showBadge,
    this.dotSize = 10,
    this.color = const Color(0xFFE53935),
  });

  @override
  Widget build(BuildContext context) {
    if (!showBadge) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -1,
          right: -1,
          child: Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).scaffoldBackgroundColor,
                width: 1.6,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
