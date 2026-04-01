import 'package:flutter/material.dart';

import '../core/constants/api_constants.dart';
import '../data/models/issue_model.dart';
import '../data/services/api_client.dart';
import '../data/services/issue_service.dart';

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
      _issues.where((issue) => issue.status == 'OPEN').toList();
  List<IssueModel> get processingIssues =>
      _issues.where((issue) => issue.status == 'PROCESSING').toList();

  Future<void> fetchIssues(int hostId, {String? issueType}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _issues = await _service.getIssues(hostId, issueType: issueType);
    } catch (_) {
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
    } catch (_) {
      _error = 'Không tải được chi tiết khiếu nại';
      notifyListeners();
    }
  }

  Future<void> fetchIssueDetailByTenant(int userId, int issueId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (_issues.isEmpty || !_issues.any((item) => item.issueId == issueId)) {
        final response = await ApiClient.instance.tenantDio.get(
          ApiConstants.tenantIssues,
          queryParameters: {'userId': userId},
        );
        _issues = (response.data['data'] as List)
            .map((item) => IssueModel.fromJson(item))
            .toList();
      }

      _selected = _issues.cast<IssueModel?>().firstWhere(
            (item) => item?.issueId == issueId,
            orElse: () => null,
          );

      if (_selected == null) {
        _error = 'Không tải được chi tiết khiếu nại';
      }
    } catch (_) {
      _error = 'Không tải được chi tiết khiếu nại';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateStatus(
    int issueId,
    String status,
    String? handlerNote,
  ) async {
    try {
      await _service.updateStatus(issueId, status, handlerNote);
      final index = _issues.indexWhere((item) => item.issueId == issueId);
      if (index != -1) {
        _selected = await _service.getIssueDetail(issueId);
        _issues[index] = _selected!;
        notifyListeners();
      }
      return true;
    } catch (_) {
      _error = 'Cập nhật trạng thái thất bại';
      notifyListeners();
      return false;
    }
  }

  Future<void> fetchIssuesByTenant(int userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await ApiClient.instance.tenantDio.get(
        ApiConstants.tenantIssues,
        queryParameters: {'userId': userId},
      );
      _issues = (response.data['data'] as List)
          .map((item) => IssueModel.fromJson(item))
          .toList();
    } catch (_) {
      _error = 'Không tải được danh sách khiếu nại';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createIssueByTenant({
    required int userId,
    required String title,
    String? description,
    String priority = 'MEDIUM',
    String issueType = 'GENERAL',
    String? suggestedServiceName,
    String? suggestionNote,
  }) async {
    final response = await ApiClient.instance.tenantDio.post(
      ApiConstants.tenantIssues,
      queryParameters: {'userId': userId},
      data: {
        'title': title,
        'description': description,
        'priority': priority,
        'issueType': issueType,
        'suggestedServiceName': suggestedServiceName,
        'suggestionNote': suggestionNote,
      },
    );
    final newIssue = IssueModel.fromJson(response.data['data']);
    _issues.insert(0, newIssue);
    notifyListeners();
  }

  Future<void> rateIssue({
    required int issueId,
    required int userId,
    required int rating,
    String? feedback,
  }) async {
    final response = await ApiClient.instance.tenantDio.patch(
      '${ApiConstants.tenantIssues}/$issueId/rating',
      queryParameters: {'userId': userId},
      data: {
        'rating': rating,
        'tenantFeedback': feedback,
      },
    );
    final updated = IssueModel.fromJson(response.data['data']);
    _selected = updated;
    final index = _issues.indexWhere((item) => item.issueId == issueId);
    if (index != -1) {
      _issues[index] = updated;
    }
    notifyListeners();
  }
}
