import 'admin_alert_model.dart';
import 'admin_json_utils.dart';

class AdminDashboardModel {
  final int totalUsers;
  final int totalHosts;
  final int totalTenants;
  final int totalRooms;
  final int totalContracts;
  final double occupancyRate;
  final double totalRevenue;
  final double thisMonthRevenue;
  final int overdueInvoices;
  final int activeContracts;
  final List<AdminAlertModel> alerts;

  const AdminDashboardModel({
    required this.totalUsers,
    required this.totalHosts,
    required this.totalTenants,
    required this.totalRooms,
    required this.totalContracts,
    required this.occupancyRate,
    required this.totalRevenue,
    required this.thisMonthRevenue,
    required this.overdueInvoices,
    required this.activeContracts,
    required this.alerts,
  });

  factory AdminDashboardModel.fromJson(Map<String, dynamic> json) {
    final rawAlerts = json['alerts'];
    return AdminDashboardModel(
      totalUsers: adminParseInt(json['totalUsers']),
      totalHosts: adminParseInt(json['totalHosts']),
      totalTenants: adminParseInt(json['totalTenants']),
      totalRooms: adminParseInt(json['totalRooms']),
      totalContracts: adminParseInt(json['totalContracts']),
      occupancyRate: adminParseDouble(json['occupancyRate']),
      totalRevenue: adminParseDouble(json['totalRevenue']),
      thisMonthRevenue: adminParseDouble(json['thisMonthRevenue']),
      overdueInvoices: adminParseInt(json['overdueInvoices']),
      activeContracts: adminParseInt(json['activeContracts']),
      alerts: rawAlerts is List
          ? rawAlerts
              .whereType<Map<String, dynamic>>()
              .map(AdminAlertModel.fromJson)
              .toList()
          : const [],
    );
  }
}
