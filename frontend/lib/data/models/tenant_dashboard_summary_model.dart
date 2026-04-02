import 'contract_model.dart';

class TenantDashboardSummaryModel {
  final ContractModel? currentContract;
  final int unpaidCount;
  final int overdueCount;
  final int openIssueCount;
  final int unreadCount;

  const TenantDashboardSummaryModel({
    required this.currentContract,
    required this.unpaidCount,
    required this.overdueCount,
    required this.openIssueCount,
    required this.unreadCount,
  });

  factory TenantDashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final contractJson = json['currentContract'];
    return TenantDashboardSummaryModel(
      currentContract: contractJson is Map<String, dynamic>
          ? ContractModel.fromTenantJson(contractJson)
          : null,
      unpaidCount: _toInt(json['unpaidCount']),
      overdueCount: _toInt(json['overdueCount']),
      openIssueCount: _toInt(json['openIssueCount']),
      unreadCount: _toInt(json['unreadCount']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }
}
