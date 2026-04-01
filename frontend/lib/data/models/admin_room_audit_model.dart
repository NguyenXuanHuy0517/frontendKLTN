import 'admin_json_utils.dart';

class AdminRoomAuditModel {
  final int roomId;
  final String roomCode;
  final String areaName;
  final String hostName;
  final String status;
  final double basePrice;
  final String currentTenantName;
  final int daysWithoutInvoice;
  final bool hasMissingInvoice;

  const AdminRoomAuditModel({
    required this.roomId,
    required this.roomCode,
    required this.areaName,
    required this.hostName,
    required this.status,
    required this.basePrice,
    required this.currentTenantName,
    required this.daysWithoutInvoice,
    required this.hasMissingInvoice,
  });

  factory AdminRoomAuditModel.fromJson(Map<String, dynamic> json) {
    final daysWithoutInvoice = adminParseInt(json['daysWithoutInvoice']);
    return AdminRoomAuditModel(
      roomId: adminParseInt(json['roomId']),
      roomCode: adminParseString(json['roomCode'], '---'),
      areaName: adminParseString(json['areaName']),
      hostName: adminParseString(json['hostName']),
      status: adminParseString(json['status'], 'UNKNOWN'),
      basePrice: adminParseDouble(json['basePrice']),
      currentTenantName: adminParseString(json['currentTenantName']),
      daysWithoutInvoice: daysWithoutInvoice,
      hasMissingInvoice: adminParseBool(
        json['hasMissingInvoice'],
        daysWithoutInvoice > 0,
      ),
    );
  }
}
