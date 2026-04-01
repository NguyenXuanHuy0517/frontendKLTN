import 'admin_json_utils.dart';

class AdminAlertModel {
  final String title;
  final String description;
  final String severity;
  final int count;
  final String? route;

  const AdminAlertModel({
    required this.title,
    required this.description,
    required this.severity,
    required this.count,
    this.route,
  });

  factory AdminAlertModel.fromJson(Map<String, dynamic> json) {
    return AdminAlertModel(
      title: adminParseString(json['title'], 'Canh bao he thong'),
      description: adminParseString(json['description']),
      severity: adminParseString(json['severity'], 'info').toLowerCase(),
      count: adminParseInt(json['count']),
      route: json['route'] == null ? null : adminParseString(json['route']),
    );
  }
}
