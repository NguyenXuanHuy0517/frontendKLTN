import 'package:flutter/material.dart';

import '../data/models/issue_model.dart';
import '../data/services/issue_service.dart';
import 'paged_list_state.dart';

class HostIssueListProvider extends ChangeNotifier {
  static const _pageSize = 20;

  final _service = IssueService();

  PagedListState<IssueModel> _state = const PagedListState<IssueModel>();
  int? _hostId;
  String _status = '';
  String _issueType = '';
  String _search = '';

  PagedListState<IssueModel> get state => _state;
  String get status => _status;
  String get issueType => _issueType;
  String get search => _search;

  Future<void> bootstrap({required int hostId}) async {
    _hostId = hostId;
    await refresh();
  }

  Future<void> applyFilters({
    String? status,
    String? issueType,
    String? search,
  }) async {
    final nextStatus = status ?? _status;
    final nextIssueType = issueType ?? _issueType;
    final nextSearch = (search ?? _search).trim();
    if (_status == nextStatus &&
        _issueType == nextIssueType &&
        _search == nextSearch) {
      return;
    }
    _status = nextStatus;
    _issueType = nextIssueType;
    _search = nextSearch;
    await refresh();
  }

  Future<void> refresh() => _load(refresh: true);

  Future<void> loadMore() => _load(refresh: false);

  Future<void> _load({required bool refresh}) async {
    final hostId = _hostId;
    if (hostId == null) return;

    if (refresh) {
      _state = _state.copyWith(loading: true, loadingMore: false, error: null);
      notifyListeners();
    } else {
      if (_state.loadingMore || !_state.hasNext) return;
      _state = _state.copyWith(loadingMore: true, error: null);
      notifyListeners();
    }

    try {
      final result = await _service.getIssuesPage(
        hostId: hostId,
        status: _status,
        issueType: _issueType,
        search: _search,
        page: refresh ? 0 : _state.page + 1,
        size: _pageSize,
      );

      _state = _state.copyWith(
        items: refresh ? result.items : [..._state.items, ...result.items],
        page: result.page,
        totalItems: result.totalItems,
        hasNext: result.hasNext,
        loading: false,
        loadingMore: false,
        error: null,
      );
    } catch (_) {
      _state = _state.copyWith(
        loading: false,
        loadingMore: false,
        error: 'Khong tai duoc danh sach khieu nai.',
      );
    }

    notifyListeners();
  }
}
