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
      invoiceId: json['invoiceId'],
      invoiceCode: json['invoiceCode'] ?? '',
      tenantName: json['tenantName'] ?? '',
      roomCode: json['roomCode'] ?? '',
      billingMonth: json['billingMonth'] ?? 0,
      billingYear: json['billingYear'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'UNPAID',
      createdAt: json['createdAt'],
    );
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
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      invoiceId: json['invoiceId'],
      invoiceCode: json['invoiceCode'] ?? '',
      tenantName: json['tenantName'] ?? '',
      roomCode: json['roomCode'] ?? '',
      billingMonth: json['billingMonth'] ?? 0,
      billingYear: json['billingYear'] ?? 0,
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      status: json['status'] ?? 'UNPAID',
      createdAt: json['createdAt'],
      rentAmount: (json['rentAmount'] ?? 0).toDouble(),
      elecOld: json['elecOld'] ?? 0,
      elecNew: json['elecNew'] ?? 0,
      elecPrice: (json['elecPrice'] ?? 0).toDouble(),
      elecAmount: (json['elecAmount'] ?? 0).toDouble(),
      waterOld: json['waterOld'] ?? 0,
      waterNew: json['waterNew'] ?? 0,
      waterPrice: (json['waterPrice'] ?? 0).toDouble(),
      waterAmount: (json['waterAmount'] ?? 0).toDouble(),
      serviceAmount: (json['serviceAmount'] ?? 0).toDouble(),
      serviceNames: List<String>.from(json['serviceNames'] ?? []),
      paidAt: json['paidAt'],
    );
  }
}