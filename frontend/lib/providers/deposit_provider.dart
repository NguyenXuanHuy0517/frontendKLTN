import 'package:flutter/material.dart';
import '../data/models/deposit_model.dart';
import '../data/services/deposit_service.dart';

class DepositProvider extends ChangeNotifier {
  final _service = DepositService();

  List<DepositModel> _deposits = [];
  bool _loading = false;
  String? _error;

  List<DepositModel> get deposits => _deposits;
  bool get loading => _loading;
  String? get error => _error;

  List<DepositModel> get pendingDeposits =>
      _deposits.where((d) => d.status == 'PENDING').toList();

  Future<void> fetchDeposits(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _deposits = await _service.getDeposits(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách đặt cọc';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> createDeposit(Map<String, dynamic> data) async {
    try {
      final deposit = await _service.createDeposit(data);
      _deposits.add(deposit);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tạo đặt cọc thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmDeposit(int depositId, int confirmedById) async {
    try {
      await _service.confirmDeposit(depositId, confirmedById);
      final idx = _deposits.indexWhere((d) => d.depositId == depositId);
      if (idx != -1) {
        _deposits.removeAt(idx);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Xác nhận đặt cọc thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> refundDeposit(int depositId) async {
    try {
      await _service.refundDeposit(depositId);
      final idx = _deposits.indexWhere((d) => d.depositId == depositId);
      if (idx != -1) {
        _deposits.removeAt(idx);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Hoàn cọc thất bại';
      notifyListeners();
      return false;
    }
  }
}
