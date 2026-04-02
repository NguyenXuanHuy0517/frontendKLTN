class AreaModel {
  final int areaId;
  final String areaName;
  final String address;
  final String? ward;
  final String? district;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? description;
  final int totalRooms;
  final int availableRooms;
  final int rentedRooms;
  final int maintenanceRooms;

  AreaModel({
    required this.areaId,
    required this.areaName,
    required this.address,
    this.ward,
    this.district,
    this.city,
    this.latitude,
    this.longitude,
    this.description,
    required this.totalRooms,
    required this.availableRooms,
    required this.rentedRooms,
    required this.maintenanceRooms,
  });

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      areaId: json['areaId'],
      areaName: json['areaName'],
      address: json['address'],
      ward: json['ward'],
      district: json['district'],
      city: json['city'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      description: json['description'],
      totalRooms: json['totalRooms'] ?? 0,
      availableRooms: json['availableRooms'] ?? 0,
      rentedRooms: json['rentedRooms'] ?? 0,
      maintenanceRooms: json['maintenanceRooms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'areaName': areaName,
      'address': address,
      'ward': ward,
      'district': district,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'description': description,
    };
  }
}
