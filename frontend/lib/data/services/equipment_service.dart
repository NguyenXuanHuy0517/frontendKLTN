import '../models/equipment_model.dart';
import '../models/room_asset_model.dart';
import 'api_client.dart';

class EquipmentService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<EquipmentModel>> getEquipments() async {
    final res = await _dio.get('/api/host/equipments');
    return (res.data['data'] as List)
        .map((item) => EquipmentModel.fromJson(item))
        .toList();
  }

  Future<List<RoomAssetModel>> getRoomAssets(int roomId) async {
    final res = await _dio.get('/api/host/rooms/$roomId/assets');
    return (res.data['data'] as List)
        .map((item) => RoomAssetModel.fromJson(item))
        .toList();
  }

  Future<RoomAssetModel> addRoomAsset({
    required int roomId,
    required int equipmentId,
    String? assignedDate,
    String? note,
  }) async {
    final res = await _dio.post(
      '/api/host/rooms/$roomId/assets',
      data: {
        'equipmentId': equipmentId,
        'assignedDate': assignedDate,
        'note': note,
      },
    );
    return RoomAssetModel.fromJson(res.data['data']);
  }

  Future<void> removeRoomAsset(int roomId, int equipmentId) async {
    await _dio.delete('/api/host/rooms/$roomId/assets/$equipmentId');
  }
}
