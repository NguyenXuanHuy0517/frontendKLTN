class EquipmentModel {
  final int equipmentId;
  final String name;
  final String? serialNumber;
  final String? status;
  final String? note;

  const EquipmentModel({
    required this.equipmentId,
    required this.name,
    this.serialNumber,
    this.status,
    this.note,
  });

  factory EquipmentModel.fromJson(Map<String, dynamic> json) {
    return EquipmentModel(
      equipmentId: json['equipmentId'],
      name: json['name'] ?? '',
      serialNumber: json['serialNumber'],
      status: json['status'],
      note: json['note'],
    );
  }
}
