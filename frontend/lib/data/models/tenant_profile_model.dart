class TenantProfileModel {
  final int userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String? idCardNumber;
  final String? avatarUrl;
  final String role;

  const TenantProfileModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    this.idCardNumber,
    this.avatarUrl,
    required this.role,
  });

  factory TenantProfileModel.fromJson(Map<String, dynamic> json) {
    return TenantProfileModel(
      userId: json['userId'] as int,
      fullName: (json['fullName'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      phoneNumber: (json['phoneNumber'] ?? '') as String,
      idCardNumber: json['idCardNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      role: (json['role'] ?? 'TENANT') as String,
    );
  }
}
