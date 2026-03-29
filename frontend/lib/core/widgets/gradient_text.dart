import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final List<Color> colors;

  const GradientText(
      this.text, {
        super.key,
        this.style,
        this.colors = AppColors.gradient,
      });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => LinearGradient(
        colors: colors,
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(bounds),
      child: Text(text, style: style),
    );
  }
}