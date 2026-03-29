import 'package:flutter/material.dart';
import '../data/models/area_model.dart';
import '../data/services/area_service.dart';

class AreaProvider extends ChangeNotifier {
  final _service = AreaService();

  List<AreaModel> _areas = [];
  bool _loading = false;
  String? _error;

  List<AreaModel> get areas => _areas;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchAreas(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _areas = await _service.getAreas(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách khu trọ';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createArea(int hostId, Map<String, dynamic> data) async {
    try {
      final area = await _service.createArea(hostId, data);
      _areas.add(area);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tạo khu trọ thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateArea(int areaId, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateArea(areaId, data);
      final idx = _areas.indexWhere((a) => a.areaId == areaId);
      if (idx != -1) {
        _areas[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Cập nhật khu trọ thất bại';
      notifyListeners();
      return false;
    }
  }
}