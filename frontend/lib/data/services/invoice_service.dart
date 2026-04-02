import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/api_constants.dart';
import '../models/invoice_model.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class InvoiceService {
  final _hostDio = ApiClient.instance.hostDio;
  final _tenantDio = ApiClient.instance.tenantDio;

  Future<List<InvoiceModel>> getInvoices(int hostId) async {
    final res = await _hostDio.get(
      ApiConstants.invoices,
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => InvoiceModel.fromJson(e))
        .toList();
  }

  Future<PagedResult<InvoiceModel>> getInvoicesPage({
    required int hostId,
    String? status,
    String? search,
    int? month,
    int? year,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final res = await _hostDio.get(
      '${ApiConstants.invoices}/paged',
      queryParameters: {
        'hostId': hostId,
        'page': page,
        'size': size,
        'sort': sort,
        if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
        if (month != null) 'month': month,
        if (year != null) 'year': year,
      },
    );
    return PagedResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
      InvoiceModel.fromJson,
    );
  }

  Future<PagedResult<InvoiceModel>> getTenantInvoicesPage({
    required int userId,
    String? status,
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final res = await _tenantDio.get(
      '${ApiConstants.tenantInvoices}/paged',
      queryParameters: {
        'userId': userId,
        'page': page,
        'size': size,
        'sort': sort,
        if ((status ?? '').trim().isNotEmpty) 'status': status!.trim(),
        if ((search ?? '').trim().isNotEmpty) 'search': search!.trim(),
      },
    );
    return PagedResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
      InvoiceModel.fromJson,
    );
  }

  Future<InvoiceDetailModel> getInvoiceDetail(int invoiceId) async {
    final res = await _hostDio.get('${ApiConstants.invoices}/$invoiceId');
    return InvoiceDetailModel.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<InvoiceDetailModel> getTenantInvoiceDetail(int invoiceId, int userId) async {
    final res = await _tenantDio.get(
      '${ApiConstants.tenantInvoices}/$invoiceId',
      queryParameters: {'userId': userId},
    );
    return InvoiceDetailModel.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<List<InvoiceModel>> getOverdueInvoices(int hostId) async {
    final res = await _hostDio.get(
      '${ApiConstants.invoices}/overdue',
      queryParameters: {'hostId': hostId},
    );
    return (res.data['data'] as List)
        .map((e) => InvoiceModel.fromJson(e))
        .toList();
  }

  Future<InvoiceDetailModel> updateMeterReading(
    int invoiceId,
    Map<String, dynamic> data,
  ) async {
    final res = await _hostDio.put(
      '${ApiConstants.invoices}/$invoiceId/meters',
      data: data,
    );
    return InvoiceDetailModel.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> confirmPayment(int invoiceId, int paidById) async {
    await _hostDio.patch(
      '${ApiConstants.invoices}/$invoiceId/pay',
      queryParameters: {'paidById': paidById},
    );
  }

  Future<InvoiceDetailModel> submitPaymentProof({
    required int invoiceId,
    required int userId,
    required XFile file,
    String? note,
  }) async {
    final fileBytes = await file.readAsBytes();
    final normalizedNote = note?.trim();
    final filename = file.name.isNotEmpty
        ? file.name
        : 'invoice_${invoiceId}_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: filename),
      if (normalizedNote?.isNotEmpty ?? false) 'note': normalizedNote,
    });

    final res = await _tenantDio.post(
      '${ApiConstants.tenantInvoices}/$invoiceId/payment-proof',
      queryParameters: {'userId': userId},
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return InvoiceDetailModel.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }
}
