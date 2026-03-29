import 'package:flutter/material.dart';
import '../data/models/issue_model.dart';
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
      _issues.where((i) => i.status == 'OPEN').toList();
  List<IssueModel> get processingIssues =>
      _issues.where((i) => i.status == 'PROCESSING').toList();

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
}