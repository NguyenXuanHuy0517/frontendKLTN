import 'package:flutter/material.dart';
import '../data/models/invoice_model.dart';
import '../data/services/invoice_service.dart';
import '../data/services/api_client.dart';
import '../core/constants/api_constants.dart';

class InvoiceProvider extends ChangeNotifier {
  final _service = InvoiceService();

  List<InvoiceModel> _invoices = [];
  InvoiceDetailModel? _selected;
  bool _loading = false;
  String? _error;

  List<InvoiceModel> get invoices => _invoices;
  InvoiceDetailModel? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  List<InvoiceModel> get unpaidInvoices =>
      _invoices.where((i) => i.status == 'UNPAID').toList();
  List<InvoiceModel> get overdueInvoices =>
      _invoices.where((i) => i.status == 'OVERDUE').toList();

  // ── HOST methods ─────────────────────────────────────────

  Future<void> fetchInvoices(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _invoices = await _service.getInvoices(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách hóa đơn';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvoiceDetail(int invoiceId) async {
    try {
      _selected = await _service.getInvoiceDetail(invoiceId);
      notifyListeners();
    } catch (e) {
      _error = 'Không tải được chi tiết hóa đơn';
      notifyListeners();
    }
  }

  Future<bool> updateMeterReading(
      int invoiceId, Map<String, dynamic> data) async {
    try {
      _selected = await _service.updateMeterReading(invoiceId, data);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Cập nhật chỉ số thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPayment(int invoiceId, int paidById) async {
    try {
      await _service.confirmPayment(invoiceId, paidById);
      final idx = _invoices.indexWhere((i) => i.invoiceId == invoiceId);
      if (idx != -1) {
        _invoices.removeAt(idx);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Xác nhận thanh toán thất bại';
      notifyListeners();
      return false;
    }
  }

  // ── TENANT methods ────────────────────────────────────────

  /// Lấy danh sách hóa đơn của người thuê (tenant-service)
  Future<void> fetchInvoicesByTenant(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.tenantDio.get(
        ApiConstants.tenantInvoices,
        queryParameters: {'userId': userId},
      );
      _invoices = (res.data['data'] as List)
          .map((e) => InvoiceModel.fromJson(e))
          .toList();
    } catch (e) {
      _error = 'Không tải được danh sách hóa đơn';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Xem chi tiết hóa đơn (tenant-service)
  Future<void> fetchInvoiceDetailByTenant(int invoiceId, int userId) async {
    try {
      final res = await ApiClient.instance.tenantDio.get(
        '${ApiConstants.tenantInvoices}/$invoiceId',
        queryParameters: {'userId': userId},
      );
      _selected = InvoiceDetailModel.fromJson(res.data['data']);
      notifyListeners();
    } catch (e) {
      _error = 'Không tải được chi tiết hóa đơn';
      notifyListeners();
    }
  }
}