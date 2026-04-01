class ServiceModel {
  final int serviceId;
  final String serviceName;
  final double price;
  final String unitName;
  final String? description;
  final bool active;
  final int usageCount;
  final int quantity;
  final int? contractServiceId;
  final double? priceSnapshot;
  final String? unitSnapshot;
  final double? currentServicePrice;

  const ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.unitName,
    this.description,
    required this.active,
    required this.usageCount,
    this.quantity = 1,
    this.contractServiceId,
    this.priceSnapshot,
    this.unitSnapshot,
    this.currentServicePrice,
  });

  String get displayUnit {
    final snapshot = (unitSnapshot ?? '').trim();
    return snapshot.isNotEmpty ? snapshot : unitName;
  }

  double get displayPrice => priceSnapshot ?? price;

  bool get hasSnapshot =>
      priceSnapshot != null || ((unitSnapshot ?? '').trim().isNotEmpty);

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'] ?? '',
      price: _toDouble(json['price']),
      unitName: json['unitName'] ?? 'Tháng',
      description: json['description'],
      active: json['active'] ?? true,
      usageCount: json['usageCount'] ?? 0,
    );
  }

  factory ServiceModel.fromTenantJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'] ?? '',
      price: _toDouble(json['price']),
      unitName: json['unitName'] ?? 'Tháng',
      description: json['description'],
      active: true,
      usageCount: 0,
      quantity: json['quantity'] ?? 1,
      contractServiceId: json['contractServiceId'],
      priceSnapshot: _toNullableDouble(json['priceSnapshot']),
      unitSnapshot: json['unitSnapshot'],
    );
  }

  factory ServiceModel.fromContractServiceJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'] ?? '',
      price: _toDouble(json['price']),
      unitName: json['unitName'] ?? 'Tháng',
      active: true,
      usageCount: 0,
      quantity: json['quantity'] ?? 1,
      contractServiceId: json['contractServiceId'],
      currentServicePrice: _toNullableDouble(json['currentServicePrice']),
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
