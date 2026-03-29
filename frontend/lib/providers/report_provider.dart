import 'package:flutter/material.dart';
import '../data/models/report_model.dart';
import '../data/services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final _service = ReportService();

  ReportModel? _report;
  bool _loading = false;
  String? _error;

  ReportModel? get report => _report;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> fetchDashboard(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _report = await _service.getDashboard(hostId);
    } catch (e) {
      _error = 'Không tải được dữ liệu dashboard';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}