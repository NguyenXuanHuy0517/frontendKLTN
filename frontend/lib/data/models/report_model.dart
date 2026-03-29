class ReportModel {
  final double totalRevenue;
  final double previousRevenue;
  final int totalRooms;
  final int rentedRooms;
  final int availableRooms;
  final int maintenanceRooms;
  final double occupancyRate;
  final int overdueCount;
  final int openIssueCount;
  final List<String> topServices;

  ReportModel({
    required this.totalRevenue,
    required this.previousRevenue,
    required this.totalRooms,
    required this.rentedRooms,
    required this.availableRooms,
    required this.maintenanceRooms,
    required this.occupancyRate,
    required this.overdueCount,
    required this.openIssueCount,
    required this.topServices,
  });

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    return ReportModel(
      totalRevenue: (json['totalRevenue'] ?? 0).toDouble(),
      previousRevenue: (json['previousRevenue'] ?? 0).toDouble(),
      totalRooms: json['totalRooms'] ?? 0,
      rentedRooms: json['rentedRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      maintenanceRooms: json['maintenanceRooms'] ?? 0,
      occupancyRate: (json['occupancyRate'] ?? 0).toDouble(),
      overdueCount: json['overdueCount'] ?? 0,
      openIssueCount: json['openIssueCount'] ?? 0,
      topServices: List<String>.from(json['topServices'] ?? []),
    );
  }
}