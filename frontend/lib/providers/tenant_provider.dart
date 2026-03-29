import 'package:flutter/material.dart';
import '../data/models/tenant_model.dart';
import '../data/services/tenant_service.dart';

class TenantProvider extends ChangeNotifier {
  final _service = TenantService();

  List<TenantModel> _tenants = [];
  TenantModel? _selected;
  bool _loading = false;
  String? _error;

  List<TenantModel> get tenants => _tenants;
  TenantModel? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchTenants(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _tenants = await _service.getTenants(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách người thuê';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchTenantDetail(int tenantId) async {
    try {
      _selected = await _service.getTenantDetail(tenantId);
      notifyListeners();
    } catch (e) {
      _error = 'Không tải được chi tiết người thuê';
      notifyListeners();
    }
  }

  Future<bool> createTenant(Map<String, dynamic> data) async {
    try {
      final tenant = await _service.createTenant(data);
      _tenants.add(tenant);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tạo người thuê thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActive(int tenantId) async {
    try {
      await _service.toggleActive(tenantId);
      final idx = _tenants.indexWhere((t) => t.userId == tenantId);
      if (idx != -1) {
        _tenants[idx] = await _service.getTenantDetail(tenantId);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Thao tác thất bại';
      notifyListeners();
      return false;
    }
  }
}