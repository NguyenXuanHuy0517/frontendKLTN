import 'package:flutter/material.dart';

import '../data/models/admin_dashboard_model.dart';
import '../data/services/admin_service.dart';

class AdminDashboardProvider extends ChangeNotifier {
  final _service = AdminService();

  AdminDashboardModel? _dashboard;
  bool _loading = false;
  String? _error;

  AdminDashboardModel? get dashboard => _dashboard;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchDashboard() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _dashboard = await _service.getDashboard();
    } catch (_) {
      _error = 'Khong tai duoc dashboard admin';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
