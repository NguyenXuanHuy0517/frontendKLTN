import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Accent / Gradient
  static const Color accent = Color(0xFF0052FF);
  static const Color accentLight = Color(0xFF4D7CFF);
  static const Color accentDark = Color(0xFF0040CC);
  static const List<Color> gradient = [Color(0xFF0052FF), Color(0xFF4D7CFF)];

  // Light mode
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightFg = Color(0xFF0F172A);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightSubtext = Color(0xFF64748B);

  // aliases cho widgets cũ
  static const Color foregroundLight = lightFg;
  static const Color foregroundDark = darkFg;
  static const Color cardLight = lightCard;
  static const Color cardDark = darkCard;
  static const Color borderLight = lightBorder;
  static const Color borderDark = darkBorder;
  static const Color mutedForegroundLight = lightSubtext;
  static const Color mutedForegroundDark = darkSubtext;

  // Dark mode
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkFg = Color(0xFFF8FAFC);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkSubtext = Color(0xFF94A3B8);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Room status
  static const Color available = Color(0xFF10B981);
  static const Color rented = Color(0xFF0052FF);
  static const Color deposited = Color(0xFFF59E0B);
  static const Color maintenance = Color(0xFFEF4444);

  // aliases roomXxx / invoiceXxx cho widgets cũ
  static const Color roomAvailable = available;
  static const Color roomRented = rented;
  static const Color roomDeposited = deposited;
  static const Color roomMaintenance = maintenance;

  static const Color invoicePaid = success;
  static const Color invoiceUnpaid = warning;
  static const Color invoiceOverdue = error;
  static const Color invoiceDraft = Color(0xFF94A3B8);
}