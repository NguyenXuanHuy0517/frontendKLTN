import 'admin_json_utils.dart';

class AdminRevenueTopHostModel {
  final String hostName;
  final double revenue;

  const AdminRevenueTopHostModel({
    required this.hostName,
    required this.revenue,
  });

  factory AdminRevenueTopHostModel.fromJson(Map<String, dynamic> json) {
    return AdminRevenueTopHostModel(
      hostName: adminParseString(json['hostName'], 'Host'),
      revenue: adminParseDouble(json['revenue']),
    );
  }
}

class AdminRevenueModel {
  final double totalRevenue;
  final double averageRevenue;
  final Map<String, double> revenueByPeriod;
  final List<AdminRevenueTopHostModel> topHosts;

  const AdminRevenueModel({
    required this.totalRevenue,
    required this.averageRevenue,
    required this.revenueByPeriod,
    required this.topHosts,
  });

  factory AdminRevenueModel.fromJson(Map<String, dynamic> json) {
    final rawPeriods = json['revenueByPeriod'];
    final periodMap = <String, double>{};

    if (rawPeriods is Map) {
      rawPeriods.forEach((key, value) {
        periodMap['$key'] = adminParseDouble(value);
      });
    }

    final rawTopHosts = json['topHosts'];

    return AdminRevenueModel(
      totalRevenue: adminParseDouble(json['totalRevenue']),
      averageRevenue: adminParseDouble(json['averageRevenue']),
      revenueByPeriod: periodMap,
      topHosts: rawTopHosts is List
          ? rawTopHosts
              .whereType<Map<String, dynamic>>()
              .map(AdminRevenueTopHostModel.fromJson)
              .toList()
          : const [],
    );
  }
}
