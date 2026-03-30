class ContractModel {
  final int contractId;
  final String contractCode;
  final String tenantName;
  final String roomCode;
  final String areaName;
  final String startDate;
  final String endDate;
  final double actualRentPrice;
  final double? elecPriceOverride;
  final double? waterPriceOverride;
  final String status;
  final List<String> serviceNames;

  ContractModel({
    required this.contractId,
    required this.contractCode,
    required this.tenantName,
    required this.roomCode,
    required this.areaName,
    required this.startDate,
    required this.endDate,
    required this.actualRentPrice,
    this.elecPriceOverride,
    this.waterPriceOverride,
    required this.status,
    required this.serviceNames,
  });

  /// Host-service response (ContractResponseDTO)
  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      contractId: json['contractId'],
      contractCode: json['contractCode'] ?? '',
      tenantName: json['tenantName'] ?? '',
      roomCode: json['roomCode'] ?? '',
      areaName: json['areaName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      actualRentPrice: (json['actualRentPrice'] ?? 0).toDouble(),
      elecPriceOverride: json['elecPriceOverride']?.toDouble(),
      waterPriceOverride: json['waterPriceOverride']?.toDouble(),
      status: json['status'] ?? 'ACTIVE',
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
    );
  }

  /// Tenant-service response (MyContractDTO)
  factory ContractModel.fromTenantJson(Map<String, dynamic> json) {
    return ContractModel(
      contractId: json['contractId'],
      contractCode: json['contractCode'] ?? '',
      tenantName: '',                         // not returned by tenant-service
      roomCode: json['roomCode'] ?? '',
      areaName: json['areaName'] ?? '',
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      actualRentPrice: (json['actualRentPrice'] ?? 0).toDouble(),
      elecPriceOverride: json['elecPrice']?.toDouble(),
      waterPriceOverride: json['waterPrice']?.toDouble(),
      status: json['status'] ?? 'ACTIVE',
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
    );
  }
}