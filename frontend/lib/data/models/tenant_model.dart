class TenantModel {
  final int userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? idCardNumber;
  final bool active;
  final String? currentRoomCode;
  final String? contractStatus;

  TenantModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.idCardNumber,
    required this.active,
    this.currentRoomCode,
    this.contractStatus,
  });

  factory TenantModel.fromJson(Map<String, dynamic> json) {
    return TenantModel(
      userId: json['userId'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'] ?? '',
      idCardNumber: json['idCardNumber'],
      active: json['active'] ?? true,
      currentRoomCode: json['currentRoomCode'],
      contractStatus: json['contractStatus'],
    );
  }
}