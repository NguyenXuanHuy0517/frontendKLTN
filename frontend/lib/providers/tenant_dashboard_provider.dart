import 'package:flutter/material.dart';

import '../data/models/tenant_dashboard_summary_model.dart';
import '../data/services/tenant_dashboard_service.dart';

class TenantDashboardProvider extends ChangeNotifier {
  final _service = TenantDashboardService();

  TenantDashboardSummaryModel? _summary;
  bool _loading = false;
  String? _error;

  TenantDashboardSummaryModel? get summary => _summary;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchSummary(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _summary = await _service.getSummary(userId);
    } catch (_) {
      _error = 'Không tải được dữ liệu trang chủ';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
