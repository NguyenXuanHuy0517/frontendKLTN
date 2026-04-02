class RentalJoinPreviewModel {
  final String roomCode;
  final String areaName;
  final String? areaAddress;
  final String startDate;
  final String endDate;
  final double actualRentPrice;
  final double elecPrice;
  final double waterPrice;
  final String? penaltyTerms;
  final String expiresAt;

  const RentalJoinPreviewModel({
    required this.roomCode,
    required this.areaName,
    this.areaAddress,
    required this.startDate,
    required this.endDate,
    required this.actualRentPrice,
    required this.elecPrice,
    required this.waterPrice,
    this.penaltyTerms,
    required this.expiresAt,
  });

  factory RentalJoinPreviewModel.fromJson(Map<String, dynamic> json) {
    return RentalJoinPreviewModel(
      roomCode: json['roomCode'] ?? '',
      areaName: json['areaName'] ?? '',
      areaAddress: json['areaAddress'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      actualRentPrice: _toDouble(json['actualRentPrice']),
      elecPrice: _toDouble(json['elecPrice']),
      waterPrice: _toDouble(json['waterPrice']),
      penaltyTerms: json['penaltyTerms'],
      expiresAt: json['expiresAt'] ?? '',
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse('$value') ?? 0;
  }
}
