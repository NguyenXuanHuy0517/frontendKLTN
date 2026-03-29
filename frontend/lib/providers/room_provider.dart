import 'package:flutter/material.dart';
import '../data/models/room_model.dart';
import '../data/services/room_service.dart';

class RoomProvider extends ChangeNotifier {
  final _service = RoomService();

  List<RoomModel> _rooms = [];
  RoomModel? _selected;
  bool _loading = false;
  String? _error;

  List<RoomModel> get rooms => _rooms;
  RoomModel? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  List<RoomModel> get availableRooms =>
      _rooms.where((r) => r.status == 'AVAILABLE').toList();
  List<RoomModel> get rentedRooms =>
      _rooms.where((r) => r.status == 'RENTED').toList();

  Future<void> fetchRooms(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _rooms = await _service.getRooms(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách phòng';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomsByArea(int areaId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _rooms = await _service.getRoomsByArea(areaId);
    } catch (e) {
      _error = 'Không tải được danh sách phòng';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchRoomDetail(int roomId) async {
    try {
      _selected = await _service.getRoomDetail(roomId);
      notifyListeners();
    } catch (e) {
      _error = 'Không tải được chi tiết phòng';
      notifyListeners();
    }
  }

  Future<bool> createRoom(Map<String, dynamic> data) async {
    try {
      final room = await _service.createRoom(data);
      _rooms.add(room);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tạo phòng thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRoom(int roomId, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateRoom(roomId, data);
      final idx = _rooms.indexWhere((r) => r.roomId == roomId);
      if (idx != -1) {
        _rooms[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Cập nhật phòng thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateStatus(
      int roomId, String status, String? note, int changedById) async {
    try {
      await _service.updateStatus(roomId, status, note, changedById);
      final idx = _rooms.indexWhere((r) => r.roomId == roomId);
      if (idx != -1) {
        _rooms[idx] = await _service.getRoomDetail(roomId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Cập nhật trạng thái thất bại';
      notifyListeners();
      return false;
    }
  }
}