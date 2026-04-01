class RoomAssetModel {
  final int equipmentId;
  final String equipmentName;
  final String? serialNumber;
  final String? status;
  final String? assignedDate;
  final String? note;

  const RoomAssetModel({
    required this.equipmentId,
    required this.equipmentName,
    this.serialNumber,
    this.status,
    this.assignedDate,
    this.note,
  });

  factory RoomAssetModel.fromJson(Map<String, dynamic> json) {
    return RoomAssetModel(
      equipmentId: json['equipmentId'],
      equipmentName: json['equipmentName'] ?? '',
      serialNumber: json['serialNumber'],
      status: json['status'],
      assignedDate: json['assignedDate'],
      note: json['note'],
    );
  }
}
