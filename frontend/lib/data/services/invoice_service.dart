import '../models/invoice_model.dart';
import 'api_client.dart';
import '../../core/constants/api_constants.dart';

class InvoiceService {
  final _dio = ApiClient.instance.hostDio;

  Future<List<InvoiceModel>> getInvoices(int hostId) async {
    final res = await _dio.get(
      ApiConstants.invoices,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => InvoiceModel.fromJson(e))
        .toList();
  }

  Future<InvoiceDetailModel> getInvoiceDetail(int invoiceId) async {
    final res = await _dio.get('${ApiConstants.invoices}/$invoiceId');
    return InvoiceDetailModel.fromJson(res.data['data']);
  }

  Future<List<InvoiceModel>> getOverdueInvoices(int hostId) async {
    final res = await _dio.get(
      '${ApiConstants.invoices}/overdue',
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => InvoiceModel.fromJson(e))
        .toList();
  }

  Future<InvoiceDetailModel> updateMeterReading(
      int invoiceId, Map<String, dynamic> data) async {
    final res = await _dio.put(
      '${ApiConstants.invoices}/$invoiceId/meters',
      data: data,
    );
    return InvoiceDetailModel.fromJson(res.data['data']);
  }

  Future<void> confirmPayment(int invoiceId, int paidById) async {
    await _dio.patch(
      '${ApiConstants.invoices}/$invoiceId/pay',
      queryParameters: {'paidById': paidById},
    );
  }
}