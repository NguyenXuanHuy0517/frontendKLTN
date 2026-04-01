import 'package:flutter/material.dart';

import '../data/models/admin_host_model.dart';
import '../data/services/admin_service.dart';

class AdminHostProvider extends ChangeNotifier {
  final _service = AdminService();

  List<AdminHostModel> _hosts = [];
  AdminHostModel? _selected;
  bool _loading = false;
  bool _detailLoading = false;
  bool _statusUpdating = false;
  String? _error;

  List<AdminHostModel> get hosts => _hosts;
  AdminHostModel? get selected => _selected;
  bool get loading => _loading;
  bool get detailLoading => _detailLoading;
  bool get statusUpdating => _statusUpdating;
  String? get error => _error;

  Future<void> fetchHosts({String? status, String? keyword}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _hosts = await _service.getHosts(status: status, keyword: keyword);
    } catch (_) {
      _error = 'Khong tai duoc danh sach host';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchHostDetail(int hostId) async {
    _detailLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selected = await _service.getHostDetail(hostId);
    } catch (_) {
      _error = 'Khong tai duoc chi tiet host';
    } finally {
      _detailLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateHostStatus(
    int hostId, {
    required bool active,
    required String reason,
    String? note,
  }) async {
    _statusUpdating = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateHostStatus(
        hostId,
        active: active,
        reason: reason,
        note: note,
      );
      await fetchHostDetail(hostId);
      await fetchHosts();
      return true;
    } catch (_) {
      _error = 'Khong cap nhat duoc trang thai host';
      _statusUpdating = false;
      notifyListeners();
      return false;
    } finally {
      _statusUpdating = false;
      notifyListeners();
    }
  }
}
