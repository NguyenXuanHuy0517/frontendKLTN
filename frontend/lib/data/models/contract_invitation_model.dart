class ContractInvitationModel {
  final String inviteCode;
  final String expiresAt;
  final String roomCode;
  final String areaName;
  final String? areaAddress;
  final String startDate;
  final String endDate;
  final double actualRentPrice;
  final double? elecPriceOverride;
  final double? waterPriceOverride;
  final String? penaltyTerms;

  const ContractInvitationModel({
    required this.inviteCode,
    required this.expiresAt,
    required this.roomCode,
    required this.areaName,
    this.areaAddress,
    required this.startDate,
    required this.endDate,
    required this.actualRentPrice,
    this.elecPriceOverride,
    this.waterPriceOverride,
    this.penaltyTerms,
  });

  factory ContractInvitationModel.fromJson(Map<String, dynamic> json) {
    return ContractInvitationModel(
      inviteCode: json['inviteCode'] ?? '',
      expiresAt: json['expiresAt'] ?? '',
      roomCode: json['roomCode'] ?? '',
      areaName: json['areaName'] ?? '',
      areaAddress: json['areaAddress'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      actualRentPrice: _toDouble(json['actualRentPrice']),
      elecPriceOverride: _toNullableDouble(json['elecPriceOverride']),
      waterPriceOverride: _toNullableDouble(json['waterPriceOverride']),
      penaltyTerms: json['penaltyTerms'],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }

  static double? _toNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }
}
