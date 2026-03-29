import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  /// Tự động chọn host phù hợp theo nền tảng:
  ///   - Web (browser)        → localhost
  ///   - Android Emulator     → 10.0.2.2  (alias localhost của máy host)
  ///   - iOS Simulator        → localhost
  ///   - Thiết bị thật        → đổi thành IP LAN của máy chủ, VD: 192.168.1.x
  static String get _host {
    if (kIsWeb) return 'localhost';
    // iOS Simulator cũng dùng localhost
    // Android Emulator dùng 10.0.2.2
    // Nếu test trên thiết bị thật: đổi thành IP máy chạy backend
    return '10.0.2.2';
  }

  static String get baseAuthUrl => 'http://$_host:8081';
  static String get baseHostUrl => 'http://$_host:8082';

  // Auth
  static const String login    = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Host
  static const String areas     = '/api/host/areas';
  static const String rooms     = '/api/host/rooms';
  static const String tenants   = '/api/host/tenants';
  static const String deposits  = '/api/host/deposits';
  static const String contracts = '/api/host/contracts';
  static const String services  = '/api/host/services';
  static const String invoices  = '/api/host/invoices';
  static const String issues    = '/api/host/issues';
  static const String reports   = '/api/host/reports/dashboard';
}