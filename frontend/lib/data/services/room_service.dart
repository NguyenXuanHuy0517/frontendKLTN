import '../models/room_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class RoomService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<RoomModel>> getRooms(int hostId) async {
    final res = await _dio.get(
      ApiConstants.rooms,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => RoomModel.fromJson(e))
        .toList();
  }

  Future<List<RoomModel>> getRoomsByArea(int areaId) async {
    final res = await _dio.get('${ApiConstants.rooms}/area/$areaId');
    return (res.data['data'] as List)
        .map((e) => RoomModel.fromJson(e))
        .toList();
  }

  Future<RoomModel> getRoomDetail(int roomId) async {
    final res = await _dio.get('${ApiConstants.rooms}/$roomId');
    return RoomModel.fromJson(res.data['data']);
  }

  Future<RoomModel> createRoom(Map<String, dynamic> data) async {
    final res = await _dio.post(ApiConstants.rooms, data: data);
    return RoomModel.fromJson(res.data['data']);
  }

  Future<RoomModel> updateRoom(int roomId, Map<String, dynamic> data) async {
    final res = await _dio.put('${ApiConstants.rooms}/$roomId', data: data);
    return RoomModel.fromJson(res.data['data']);
  }

  Future<void> updateStatus(
      int roomId, String status, String? note, int changedById) async {
    await _dio.patch(
      '${ApiConstants.rooms}/$roomId/status',
      queryParameters: {'changedById': changedById},
      data: {'status': status, 'note': note},
    );
  }
}