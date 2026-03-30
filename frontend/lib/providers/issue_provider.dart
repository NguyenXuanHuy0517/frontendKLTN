import 'package:flutter/material.dart';
import '../data/models/issue_model.dart';
import '../data/services/issue_service.dart';
import '../data/services/api_client.dart';
import '../core/constants/api_constants.dart';

class IssueProvider extends ChangeNotifier {
  final _service = IssueService();

  List<IssueModel> _issues = [];
  IssueModel? _selected;
  bool _loading = false;
  String? _error;

  List<IssueModel> get issues => _issues;
  IssueModel? get selected => _selected;
  bool get loading => _loading;
  String? get error => _error;

  List<IssueModel> get openIssues =>
      _issues.where((i) => i.status == 'OPEN').toList();
  List<IssueModel> get processingIssues =>
      _issues.where((i) => i.status == 'PROCESSING').toList();

  // ── HOST methods ─────────────────────────────────────────

  Future<void> fetchIssues(int hostId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _issues = await _service.getIssues(hostId);
    } catch (e) {
      _error = 'Không tải được danh sách khiếu nại';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> fetchIssueDetail(int issueId) async {
    try {
      _selected = await _service.getIssueDetail(issueId);
      notifyListeners();
    } catch (e) {
      _error = 'Không tải được chi tiết khiếu nại';
      notifyListeners();
    }
  }

  Future<bool> updateStatus(
      int issueId, String status, String? handlerNote) async {
    try {
      await _service.updateStatus(issueId, status, handlerNote);
      final idx = _issues.indexWhere((i) => i.issueId == issueId);
      if (idx != -1) {
        _selected = await _service.getIssueDetail(issueId);
        _issues[idx] = _selected!;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = 'Cập nhật trạng thái thất bại';
      notifyListeners();
      return false;
    }
  }

  // ── TENANT methods ────────────────────────────────────────

  /// Lấy danh sách khiếu nại của người thuê (tenant-service)
  Future<void> fetchIssuesByTenant(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final res = await ApiClient.instance.tenantDio.get(
        ApiConstants.tenantIssues,
        queryParameters: {'userId': userId},
      );
      _issues = (res.data['data'] as List)
          .map((e) => IssueModel.fromJson(e))
          .toList();
    } catch (e) {
      _error = 'Không tải được danh sách khiếu nại';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Tạo khiếu nại mới (tenant-service)
  Future<void> createIssueByTenant({
    required int userId,
    required String title,
    String? description,
    String priority = 'MEDIUM',
  }) async {
    final res = await ApiClient.instance.tenantDio.post(
      ApiConstants.tenantIssues,
      queryParameters: {'userId': userId},
      data: {
        'title': title,
        'description': description,
        'priority': priority,
      },
    );
    final newIssue = IssueModel.fromJson(res.data['data']);
    _issues.insert(0, newIssue);
    notifyListeners();
  }

  /// Đánh giá khiếu nại sau khi được giải quyết (tenant-service)
  Future<void> rateIssue({
    required int issueId,
    required int userId,
    required int rating,
    String? feedback,
  }) async {
    final res = await ApiClient.instance.tenantDio.patch(
      '${ApiConstants.tenantIssues}/$issueId/rating',
      queryParameters: {'userId': userId},
      data: {
        'rating': rating,
        'tenantFeedback': feedback,
      },
    );
    final updated = IssueModel.fromJson(res.data['data']);
    _selected = updated;
    final idx = _issues.indexWhere((i) => i.issueId == issueId);
    if (idx != -1) _issues[idx] = updated;
    notifyListeners();
  }
}