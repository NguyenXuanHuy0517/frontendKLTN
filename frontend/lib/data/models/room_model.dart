class RoomModel {
  final int roomId;
  final String roomCode;
  final int? floor;
  final double basePrice;
  final double elecPrice;
  final double waterPrice;
  final double? areaSize;
  final String status;
  final String? amenities;
  final String? images;
  final String? description;
  final int areaId;
  final String areaName;
  final String? currentTenantName;
  final int? currentContractId;

  RoomModel({
    required this.roomId,
    required this.roomCode,
    this.floor,
    required this.basePrice,
    required this.elecPrice,
    required this.waterPrice,
    this.areaSize,
    required this.status,
    this.amenities,
    this.images,
    this.description,
    required this.areaId,
    required this.areaName,
    this.currentTenantName,
    this.currentContractId,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      roomId: json['roomId'],
      roomCode: json['roomCode'],
      floor: json['floor'],
      basePrice: (json['basePrice'] ?? 0).toDouble(),
      elecPrice: (json['elecPrice'] ?? 0).toDouble(),
      waterPrice: (json['waterPrice'] ?? 0).toDouble(),
      areaSize: json['areaSize']?.toDouble(),
      status: json['status'] ?? 'AVAILABLE',
      amenities: json['amenities'],
      images: json['images'],
      description: json['description'],
      areaId: json['areaId'],
      areaName: json['areaName'] ?? '',
      currentTenantName: json['currentTenantName'],
      currentContractId: json['currentContractId'],
    );
  }

  List<String> get amenitiesList {
    if (amenities == null || amenities!.isEmpty) return [];
    return amenities!.split(',').map((e) => e.trim()).toList();
  }

  List<String> get imagesList {
    if (images == null || images!.isEmpty) return [];
    return images!.split(',').map((e) => e.trim()).toList();
  }
}
