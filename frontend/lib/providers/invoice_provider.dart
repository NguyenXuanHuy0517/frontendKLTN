import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/api_constants.dart';
import '../data/models/invoice_model.dart';
import '../data/services/api_client.dart';
import '../data/services/invoice_service.dart';

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
      _invoices.where((invoice) => invoice.status == 'UNPAID').toList();
  List<InvoiceModel> get overdueInvoices =>
      _invoices.where((invoice) => invoice.status == 'OVERDUE').toList();

  Future<void> fetchInvoices(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _invoices = await _service.getInvoices(hostId);
    } catch (_) {
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
    } catch (_) {
      _error = 'Không tải được chi tiết hóa đơn';
      notifyListeners();
    }
  }

  Future<bool> updateMeterReading(
    int invoiceId,
    Map<String, dynamic> data,
  ) async {
    try {
      _selected = await _service.updateMeterReading(invoiceId, data);
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Cập nhật chỉ số thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<bool> confirmPayment(int invoiceId, int paidById) async {
    try {
      await _service.confirmPayment(invoiceId, paidById);
      final index = _invoices.indexWhere((item) => item.invoiceId == invoiceId);
      if (index != -1) {
        _invoices.removeAt(index);
      }
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Xác nhận thanh toán thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchInvoicesByTenant(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.tenantDio.get(
        ApiConstants.tenantInvoices,
        queryParameters: {'userId': userId},
      );
      _invoices = (response.data['data'] as List)
          .map((item) => InvoiceModel.fromJson(item))
          .toList();
    } catch (_) {
      _error = 'Không tải được danh sách hóa đơn';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInvoiceDetailByTenant(int invoiceId, int userId) async {
    try {
      _selected = await _service.getTenantInvoiceDetail(invoiceId, userId);
      notifyListeners();
    } catch (_) {
      _error = 'Không tải được chi tiết hóa đơn';
      notifyListeners();
    }
  }

  Future<bool> submitPaymentProof({
    required int invoiceId,
    required int userId,
    required XFile file,
    String? note,
  }) async {
    try {
      final updated = await _service.submitPaymentProof(
        invoiceId: invoiceId,
        userId: userId,
        file: file,
        note: note,
      );
      _selected = updated;

      final index = _invoices.indexWhere((item) => item.invoiceId == invoiceId);
      if (index != -1) {
        _invoices[index] = InvoiceModel.fromJson({
          'invoiceId': updated.invoiceId,
          'invoiceCode': updated.invoiceCode,
          'tenantName': updated.tenantName,
          'roomCode': updated.roomCode,
          'billingMonth': updated.billingMonth,
          'billingYear': updated.billingYear,
          'totalAmount': updated.totalAmount,
          'status': updated.status,
          'dueDate': updated.dueDate,
          'paymentProofUrl': updated.paymentProofUrl,
          'paymentSubmittedAt': updated.paymentSubmittedAt,
          'paymentNote': updated.paymentNote,
          'paymentStatus': updated.paymentStatus,
          'createdAt': updated.createdAt,
        });
      }

      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Gửi minh chứng thanh toán thất bại';
      notifyListeners();
      return false;
    }
  }
}
