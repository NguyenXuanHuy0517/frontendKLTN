import 'package:flutter/material.dart';
import '../data/models/contract_model.dart';
import '../data/services/contract_service.dart';
import '../data/services/api_client.dart';
import '../core/constants/api_constants.dart';

class ContractProvider extends ChangeNotifier {
  final _service = ContractService();

  List<ContractModel> _contracts = [];
  ContractModel? _selected;
  bool _loading = false;
  String? _error;

  List<ContractModel> get contracts => _contracts;
  ContractModel? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  List<ContractModel> get activeContracts =>
      _contracts.where((c) => c.status == 'ACTIVE').toList();

  /// Hợp đồng ACTIVE hiện tại (dùng cho tenant dashboard)
  ContractModel? get currentContract {
    try {
      return _contracts.firstWhere((c) => c.status == 'ACTIVE');
    } catch (_) {
      return null;
    }
  }

  // ── HOST methods ─────────────────────────────────────────

  Future<void> fetchContracts(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _contracts = await _service.getContracts(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách hợp đồng';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchContractDetail(int contractId) async {
    try {
      _selected = await _service.getContractDetail(contractId);
      notifyListeners();
    } catch (e) {
      _error = 'Không tải được chi tiết hợp đồng';
      notifyListeners();
    }
  }

  Future<bool> createContract(Map<String, dynamic> data) async {
    try {
      final contract = await _service.createContract(data);
      _contracts.add(contract);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Tạo hợp đồng thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> extendContract(int contractId, String newEndDate) async {
    try {
      final updated = await _service.extendContract(contractId, newEndDate);
      final idx = _contracts.indexWhere((c) => c.contractId == contractId);
      if (idx != -1) {
        _contracts[idx] = updated;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Gia hạn hợp đồng thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> terminateContract(int contractId, int terminatedById) async {
    try {
      await _service.terminateContract(contractId, terminatedById);
      final idx = _contracts.indexWhere((c) => c.contractId == contractId);
      if (idx != -1) {
        _contracts.removeAt(idx);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Chấm dứt hợp đồng thất bại';
      notifyListeners();
      return false;
    }
  }

  // ── TENANT methods ────────────────────────────────────────

  /// Lấy danh sách hợp đồng của người thuê (tenant-service)
  Future<void> fetchContractsByTenant(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.tenantDio.get(
        ApiConstants.tenantContracts,
        queryParameters: {'userId': userId},
      );
      // tenant-service trả về MyContractDTO, map sang ContractModel
      _contracts = (res.data['data'] as List)
          .map((e) => ContractModel.fromTenantJson(e))
          .toList();
    } catch (e) {
      _error = 'Không tải được danh sách hợp đồng';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}