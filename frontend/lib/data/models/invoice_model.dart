class InvoiceModel {
  final int invoiceId;
  final String invoiceCode;
  final String tenantName;
  final String roomCode;
  final int billingMonth;
  final int billingYear;
  final double totalAmount;
  final String status;
  final String? createdAt;

  InvoiceModel({
    required this.invoiceId,
    required this.invoiceCode,
    required this.tenantName,
    required this.roomCode,
    required this.billingMonth,
    required this.billingYear,
    required this.totalAmount,
    required this.status,
    this.createdAt,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      invoiceId: json['invoiceId'] as int,
      invoiceCode: (json['invoiceCode'] as String?) ?? '',
      // tenant-service (MyInvoiceDTO) không có tenantName → fallback ''
      tenantName: (json['tenantName'] as String?) ?? '',
      // tenant-service (MyInvoiceDTO) không có roomCode → fallback ''
      roomCode: (json['roomCode'] as String?) ?? '',
      billingMonth: (json['billingMonth'] as int?) ?? 0,
      billingYear: (json['billingYear'] as int?) ?? 0,
      totalAmount: _toDouble(json['totalAmount']),
      status: (json['status'] as String?) ?? 'UNPAID',
      createdAt: json['createdAt'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}

// ── Detail model (host + tenant) ─────────────────────────────────────────────

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
  /// Hạn thanh toán — từ tenant-service (MyInvoiceDetailDTO.dueDate).
  /// Backend trả về kiểu LocalDate dạng "yyyy-MM-dd", không phải timestamp.
  final String? dueDate;

  InvoiceDetailModel({
    required super.invoiceId,
    required super.invoiceCode,
    required super.tenantName,
    required super.roomCode,
    required super.billingMonth,
    required super.billingYear,
    required super.totalAmount,
    required super.status,
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
    this.dueDate,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      invoiceId: json['invoiceId'] as int,
      invoiceCode: (json['invoiceCode'] as String?) ?? '',
      tenantName: (json['tenantName'] as String?) ?? '',
      roomCode: (json['roomCode'] as String?) ?? '',
      billingMonth: (json['billingMonth'] as int?) ?? 0,
      billingYear: (json['billingYear'] as int?) ?? 0,
      totalAmount: _toDouble(json['totalAmount']),
      status: (json['status'] as String?) ?? 'UNPAID',
      createdAt: json['createdAt'] as String?,
      rentAmount: _toDouble(json['rentAmount']),
      elecOld: (json['elecOld'] as int?) ?? 0,
      elecNew: (json['elecNew'] as int?) ?? 0,
      elecPrice: _toDouble(json['elecPrice']),
      elecAmount: _toDouble(json['elecAmount']),
      waterOld: (json['waterOld'] as int?) ?? 0,
      waterNew: (json['waterNew'] as int?) ?? 0,
      waterPrice: _toDouble(json['waterPrice']),
      waterAmount: _toDouble(json['waterAmount']),
      serviceAmount: _toDouble(json['serviceAmount']),
      serviceNames: _toStringList(json['serviceNames']),
      paidAt: json['paidAt'] as String?,
      // dueDate từ tenant-service là LocalDate → String "yyyy-MM-dd"
      // dueDate từ host-service có thể không tồn tại → null
      dueDate: json['dueDate'] as String?,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }
}