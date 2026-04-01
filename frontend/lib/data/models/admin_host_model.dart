import 'admin_json_utils.dart';

class AdminHostModel {
  final int userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String avatarUrl;
  final bool isActive;
  final int totalAreas;
  final int totalRooms;
  final int activeContracts;
  final int overdueInvoices;
  final int roomsWithoutInvoice;
  final int warningCount;
  final String latestStatusReason;
  final String note;

  const AdminHostModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.avatarUrl,
    required this.isActive,
    required this.totalAreas,
    required this.totalRooms,
    required this.activeContracts,
    required this.overdueInvoices,
    required this.roomsWithoutInvoice,
    required this.warningCount,
    required this.latestStatusReason,
    required this.note,
  });

  factory AdminHostModel.fromJson(Map<String, dynamic> json) {
    final overdueInvoices = adminParseInt(json['overdueInvoices']);
    final roomsWithoutInvoice = adminParseInt(json['roomsWithoutInvoice']);

    return AdminHostModel(
      userId: adminParseInt(json['userId']),
      fullName: adminParseString(json['fullName'], 'Host'),
      email: adminParseString(json['email']),
      phoneNumber: adminParseString(json['phoneNumber']),
      avatarUrl: adminParseString(json['avatarUrl']),
      isActive: adminParseBool(json['active'] ?? json['isActive'], true),
      totalAreas: adminParseInt(json['totalAreas']),
      totalRooms: adminParseInt(json['totalRooms']),
      activeContracts: adminParseInt(json['activeContracts']),
      overdueInvoices: overdueInvoices,
      roomsWithoutInvoice: roomsWithoutInvoice,
      warningCount: adminParseInt(
        json['warningCount'],
        overdueInvoices + roomsWithoutInvoice,
      ),
      latestStatusReason: adminParseString(json['latestStatusReason']),
      note: adminParseString(json['note']),
    );
  }
}
