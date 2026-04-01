import 'package:flutter/material.dart';

import '../data/models/admin_revenue_model.dart';
import '../data/services/admin_service.dart';

class AdminRevenueProvider extends ChangeNotifier {
  final _service = AdminService();

  AdminRevenueModel? _revenue;
  bool _loading = false;
  String? _error;
  String _period = 'month';

  AdminRevenueModel? get revenue => _revenue;
  bool get loading => _loading;
  String? get error => _error;
  String get period => _period;

  Future<void> fetchRevenue([String period = 'month']) async {
    _period = period;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _revenue = await _service.getRevenue(period);
    } catch (_) {
      _error = 'Khong tai duoc du lieu doanh thu';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
