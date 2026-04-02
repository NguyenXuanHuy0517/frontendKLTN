class UserModel {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String token;
  final bool requiresRentalJoin;

  UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
    this.requiresRentalJoin = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      token: json['token'],
      requiresRentalJoin: json['requiresRentalJoin'] ?? false,
    );
  }
}
