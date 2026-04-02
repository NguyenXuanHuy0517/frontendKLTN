class InvoiceModel {
  final int invoiceId;
  final String invoiceCode;
  final String tenantName;
  final String roomCode;
  final int billingMonth;
  final int billingYear;
  final double totalAmount;
  final String status;
  final String? dueDate;
  final String? paymentProofUrl;
  final String? paymentSubmittedAt;
  final String? paymentNote;
  final String? paymentStatus;
  final String? createdAt;

  const InvoiceModel({
    required this.invoiceId,
    required this.invoiceCode,
    required this.tenantName,
    required this.roomCode,
    required this.billingMonth,
    required this.billingYear,
    required this.totalAmount,
    required this.status,
    this.dueDate,
    this.paymentProofUrl,
    this.paymentSubmittedAt,
    this.paymentNote,
    this.paymentStatus,
    this.createdAt,
  });

  bool get hasPaymentProof =>
      paymentProofUrl != null && paymentProofUrl!.trim().isNotEmpty;

  bool get isPendingReview => paymentStatus?.toUpperCase() == 'PENDING_REVIEW';

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'] as int,
      invoiceCode: (json['invoiceCode'] as String?) ?? '',
      tenantName: (json['tenantName'] as String?) ?? '',
      roomCode: (json['roomCode'] as String?) ?? '',
      billingMonth: (json['billingMonth'] as int?) ?? 0,
      billingYear: (json['billingYear'] as int?) ?? 0,
      totalAmount: _toDouble(json['totalAmount']),
      status: (json['status'] as String?) ?? 'UNPAID',
      dueDate: json['dueDate'] as String?,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      paymentSubmittedAt: json['paymentSubmittedAt'] as String?,
      paymentNote: json['paymentNote'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}

class InvoiceDetailModel extends InvoiceModel {
  final double rentAmount;
  final int elecOld;
  final int elecNew;
  final double elecPrice;
  final double elecAmount;
  final int waterOld;
  final int waterNew;
  final double waterPrice;
  final double waterAmount;
  final double serviceAmount;
  final List<String> serviceNames;
  final String? paidAt;

  const InvoiceDetailModel({
    required super.invoiceId,
    required super.invoiceCode,
    required super.tenantName,
    required super.roomCode,
    required super.billingMonth,
    required super.billingYear,
    required super.totalAmount,
    required super.status,
    super.dueDate,
    super.paymentProofUrl,
    super.paymentSubmittedAt,
    super.paymentNote,
    super.paymentStatus,
    super.createdAt,
    required this.rentAmount,
    required this.elecOld,
    required this.elecNew,
    required this.elecPrice,
    required this.elecAmount,
    required this.waterOld,
    required this.waterNew,
    required this.waterPrice,
    required this.waterAmount,
    required this.serviceAmount,
    required this.serviceNames,
    this.paidAt,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      invoiceId: json['invoiceId'] as int,
      invoiceCode: (json['invoiceCode'] as String?) ?? '',
      tenantName: (json['tenantName'] as String?) ?? '',
      roomCode: (json['roomCode'] as String?) ?? '',
      billingMonth: (json['billingMonth'] as int?) ?? 0,
      billingYear: (json['billingYear'] as int?) ?? 0,
      totalAmount: InvoiceModel._toDouble(json['totalAmount']),
      status: (json['status'] as String?) ?? 'UNPAID',
      dueDate: json['dueDate'] as String?,
      paymentProofUrl: json['paymentProofUrl'] as String?,
      paymentSubmittedAt: json['paymentSubmittedAt'] as String?,
      paymentNote: json['paymentNote'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
      createdAt: json['createdAt'] as String?,
      rentAmount: InvoiceModel._toDouble(json['rentAmount']),
      elecOld: (json['elecOld'] as int?) ?? 0,
      elecNew: (json['elecNew'] as int?) ?? 0,
      elecPrice: InvoiceModel._toDouble(json['elecPrice']),
      elecAmount: InvoiceModel._toDouble(json['elecAmount']),
      waterOld: (json['waterOld'] as int?) ?? 0,
      waterNew: (json['waterNew'] as int?) ?? 0,
      waterPrice: InvoiceModel._toDouble(json['waterPrice']),
      waterAmount: InvoiceModel._toDouble(json['waterAmount']),
      serviceAmount: InvoiceModel._toDouble(json['serviceAmount']),
      serviceNames: _toStringList(json['serviceNames']),
      paidAt: json['paidAt'] as String?,
    );
  }

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return [];
  }
}
