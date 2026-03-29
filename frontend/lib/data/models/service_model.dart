class ServiceModel {
  final int serviceId;
  final String serviceName;
  final double price;
  final String unitName;
  final String? description;
  final bool active;
  final int usageCount;

  ServiceModel({
    required this.serviceId,
    required this.serviceName,
    required this.price,
    required this.unitName,
    this.description,
    required this.active,
    required this.usageCount,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      serviceId: json['serviceId'],
      serviceName: json['serviceName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      unitName: json['unitName'] ?? 'Tháng',
      description: json['description'],
      active: json['active'] ?? true,
      usageCount: json['usageCount'] ?? 0,
    );
  }
}