import 'service_model.dart';

class ContractModel {
  final int contractId;
  final String contractCode;
  final String tenantName;
  final String roomCode;
  final String areaName;
  final String? areaAddress;
  final String startDate;
  final String endDate;
  final double actualRentPrice;
  final double? elecPriceOverride;
  final double? waterPriceOverride;
  final String status;
  final List<ServiceModel> contractServices;
  final List<String> serviceNames;
  final int? daysUntilExpiry;

  const ContractModel({
    required this.contractId,
    required this.contractCode,
    required this.tenantName,
    required this.roomCode,
    required this.areaName,
    this.areaAddress,
    required this.startDate,
    required this.endDate,
    required this.actualRentPrice,
    this.elecPriceOverride,
    this.waterPriceOverride,
    required this.status,
    required this.contractServices,
    required this.serviceNames,
    this.daysUntilExpiry,
  });

  List<String> get serviceLabels {
    if (contractServices.isNotEmpty) {
      return contractServices.map((service) => service.serviceName).toList();
    }
    return serviceNames;
  }

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final contractServices = (json['contractServices'] as List? ?? [])
        .map((item) => ServiceModel.fromContractServiceJson(item))
        .toList();

    return ContractModel(
      contractId: json['contractId'],
      contractCode: json['contractCode'] ?? '',
      tenantName: json['tenantName'] ?? '',
      roomCode: json['roomCode'] ?? '',
      areaName: json['areaName'] ?? '',
      areaAddress: json['areaAddress'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      actualRentPrice: _toDouble(json['actualRentPrice']),
      elecPriceOverride: _toNullableDouble(json['elecPriceOverride']),
      waterPriceOverride: _toNullableDouble(json['waterPriceOverride']),
      status: json['status'] ?? 'ACTIVE',
      contractServices: contractServices,
      serviceNames: contractServices.isNotEmpty
          ? contractServices.map((service) => service.serviceName).toList()
          : List<String>.from(json['serviceNames'] ?? []),
      daysUntilExpiry: json['daysUntilExpiry'],
    );
  }

  factory ContractModel.fromTenantJson(Map<String, dynamic> json) {
    final contractServices = (json['contractServices'] as List? ?? [])
        .map((item) => ServiceModel.fromContractServiceJson(item))
        .toList();

    return ContractModel(
      contractId: json['contractId'],
      contractCode: json['contractCode'] ?? '',
      tenantName: '',
      roomCode: json['roomCode'] ?? '',
      areaName: json['areaName'] ?? '',
      areaAddress: json['areaAddress'],
      startDate: json['startDate'] ?? '',
      endDate: json['endDate'] ?? '',
      actualRentPrice: _toDouble(json['actualRentPrice']),
      elecPriceOverride: _toNullableDouble(json['elecPrice']),
      waterPriceOverride: _toNullableDouble(json['waterPrice']),
      status: json['status'] ?? 'ACTIVE',
      contractServices: contractServices,
      serviceNames: contractServices.isNotEmpty
          ? contractServices.map((service) => service.serviceName).toList()
          : List<String>.from(json['serviceNames'] ?? []),
      daysUntilExpiry: json['daysUntilExpiry'],
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
