import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const String _display = 'Calistoga';
  static const String _body = 'Inter';
  static const String _mono = 'JetBrainsMono';

  static const TextStyle h1 = TextStyle(
    fontFamily: _display,
    fontSize: 32,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: _display,
    fontSize: 24,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: _body,
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    height: 1.4,
  );

  // alias cho widgets cũ dùng heading3
  static const TextStyle heading3 = h3;

  static const TextStyle body = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle body2 = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _body,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle button = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
  );

  // alias cho widgets cũ dùng badge
  static const TextStyle badge = caption;

  static const TextStyle label = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.lightSubtext,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: _mono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}