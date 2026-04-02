import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  ApiConstants._();

  static String get _host {
    if (kIsWeb) return 'localhost';
    // Android emulator: 10.0.2.2 trỏ về localhost máy host
    return '10.0.2.2';
  }

  static String get baseAuthUrl => 'http://$_host:8081';
  static String get baseHostUrl => 'http://$_host:8082';
  static String get baseTenantUrl => 'http://$_host:8083';
  static String get baseAdminUrl => 'http://$_host:8084';

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '/api/auth/login';
  static const String registerTenant = '/api/auth/register/tenant';
  static const String registerHost = '/api/auth/register/host';
  static const String forgotPassword = '/api/auth/forgot-password';
  static const String resetPassword = '/api/auth/reset-password';

  // ── Host ──────────────────────────────────────────────────
  static const String areas = '/api/host/areas';
  static const String rooms = '/api/host/rooms';
  static const String tenants = '/api/host/tenants';
  static const String deposits = '/api/host/deposits';
  static const String contracts = '/api/host/contracts';
  static const String contractInvitations = '/api/host/contracts/invitations';
  static const String services = '/api/host/services';
  static const String invoices = '/api/host/invoices';
  static const String issues = '/api/host/issues';
  static const String reports = '/api/host/reports/dashboard';
  static const String hostNotifications = '/api/host/notifications';
  static const String hostAvatar = '/api/host/avatar';
  static const String adminDashboard = '/api/admin/dashboard';
  static const String adminHosts = '/api/admin/hosts';
  static const String adminRooms = '/api/admin/rooms';
  static const String adminRoomsWithoutInvoice =
      '/api/admin/rooms/without-invoice';
  static const String adminRevenue = '/api/admin/revenue';

  // ── Tenant ────────────────────────────────────────────────
  static const String tenantProfile = '/api/tenant/profile';
  static const String tenantDashboardSummary = '/api/tenant/dashboard/summary';
  static const String tenantContracts = '/api/tenant/contracts';
  static const String tenantInvoices = '/api/tenant/invoices';
  static const String tenantIssues = '/api/tenant/issues';
  static const String tenantNotifications = '/api/tenant/notifications';
  static const String tenantRentalJoinPreview =
      '/api/tenant/rental-join/preview';
  static const String tenantRentalJoinClaim = '/api/tenant/rental-join/claim';
  static const String chatbot = '/api/tenant/chatbot';
  static const String tenantAvatar = '/api/tenant/avatar';
}
